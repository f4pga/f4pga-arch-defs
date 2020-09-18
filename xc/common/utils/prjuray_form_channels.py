#!/usr/bin/env python3
""" Classify 7-series nodes and generate channels for required nodes.

Rough structure:

Create initial database import by importing tile types, tile wires, tile pips,
site types and site pins.  After importing tile types, imports the grid of
tiles.  This uses tilegrid.json, tile_type_*.json and site_type_*.json.

Once all tiles are imported, all wires in the grid are added and nodes are
formed from the sea of wires based on the tile connections description
(tileconn.json).

In order to determine what each node is used for, site pins and pips are counted
on each node (count_sites_and_pips_on_nodes).  Depending on the site pin and
pip count, the nodes are classified into one of 4 buckets:

    NULL - An unconnected node
    CHANNEL - A routing node
    EDGE_WITH_MUX - An edge between an IPIN and OPIN.
    EDGES_TO_CHANNEL - An edge between an IPIN/OPIN and a CHANNEL.

Then all CHANNEL are grouped into tracks (form_tracks) and graph nodes are
created for the CHANNELs.  Graph edges are added to connect graph nodes that are
part of the same track.

Note that IPIN and OPIN graph nodes are not added yet, as pins have not been
assigned sides of the VPR tiles yet.  This occurs in
prjuray_assign_tile_pin_direction.


"""
import argparse
import os
import datetime

import prjuray.db
import prjuray.tile
from prjuray_timing import PvtCorner

from lib.connection_database import create_tables
from lib.connection_database import NodeClassification

from form_channels import create_get_switch
from form_channels import import_phy_grid
from form_channels import import_segments
from form_channels import import_nodes
from form_channels import count_sites_and_pips_on_nodes
from form_channels import classify_nodes
from form_channels import create_vpr_grid
from form_channels import form_tracks

from prjxray_db_cache import DatabaseCache

from prjuray_define_segments import SegmentWireMap

# =============================================================================


def get_pip_timing(pip, pip_timing=None):
    """
    Returns internal R, C, Tdel and penalty cost for the given PIP. When
    pip_timing is none the function returns default values.
    """

    R = 0.0
    C = 0.0
    Tdel = 0.0

    # Timings
    if pip_timing is not None:

        if pip_timing.delays is not None:
            # Use the largest intristic delay for now.
            # This conservative on slack timing, but not on hold timing.
            #
            # nanosecond -> seconds
            Tdel = pip_timing.delays[PvtCorner.SLOW].max / 1e9

        if pip_timing.internal_capacitance is not None:
            # microFarads -> Farads
            C = pip_timing.internal_capacitance / 1e6

        if pip_timing.drive_resistance is not None:
            # milliOhms -> Ohms
            R = pip_timing.drive_resistance / 1e3

    return R, C, Tdel


def get_site_pin_timing(site_pin):
    """
    Returns internal R, C and Tdel for the given site pin
    """

    R = 0.0
    C = 0.0

    # Use the largest intristic delay for now.
    # This conservative on slack timing, but not on hold timing.

    # nanosecond -> seconds
    Tdel = site_pin.timing.delays[PvtCorner.SLOW].max / 1e9

    if isinstance(site_pin.timing, prjuray.tile.OutPinTiming):
        # milliOhms -> Ohms
        R = site_pin.timing.drive_resistance / 1e3
    elif isinstance(site_pin.timing, prjuray.tile.InPinTiming):
        # microFarads -> Farads
        C = site_pin.timing.capacitance / 1e6
    else:
        assert False, site_pin

    return R, C, Tdel


def check_pip_for_direct(pip_name):
    """
    Returns true when the given pip should be modeled as a direct connection
    """
    return False


def connect_hardpins_to_constant_network(conn, vcc_track_pkey, gnd_track_pkey):
    """
    Connect all GND_WIRE* and VCC_WIRE* nodes to VCC or GND track.
    """

    cur = conn.cursor()

    write_cur = conn.cursor()
    write_cur.execute("""BEGIN EXCLUSIVE TRANSACTION;""")

    # VCC
    cur.execute(
        """
SELECT pkey FROM wire_in_tile
WHERE name LIKE "VCC_WIRE%"
"""
    )

    for (wire_in_tile_pkey, ) in cur:
        write_cur.execute(
            """
UPDATE node SET track_pkey = ? WHERE pkey IN (
    SELECT node_pkey FROM wire WHERE wire_in_tile_pkey = ?
)
            """, (
                vcc_track_pkey,
                wire_in_tile_pkey,
            )
        )

    # GND
    cur.execute(
        """
SELECT pkey FROM wire_in_tile
WHERE name LIKE "GND_WIRE%"
"""
    )

    for (wire_in_tile_pkey, ) in cur:
        write_cur.execute(
            """
UPDATE node SET track_pkey = ? WHERE pkey IN (
    SELECT node_pkey FROM wire WHERE wire_in_tile_pkey = ?
)
            """, (
                gnd_track_pkey,
                wire_in_tile_pkey,
            )
        )

    write_cur.execute("""COMMIT TRANSACTION""")


def identify_const_nodes(conn):
    """
    Creates a new table for const nodes, identifies them and inserts their
    pkeys along with const signal name to the table.
    """

    # Create table to hold const nodes
    c = conn.cursor()
    c.execute(
        """
CREATE TABLE const_nodes(
  node_pkey INT,
  net_name TEXT,
FOREIGN KEY(node_pkey) REFERENCES node(pkey)
);
        """
    )

    # Identify and insert const source nodes
    c.execute(
        """
WITH
  wire_info(name, node_pkey) AS (
SELECT
  wire_in_tile.name, wire.node_pkey
FROM
  wire
INNER JOIN
  wire_in_tile ON wire.wire_in_tile_pkey = wire_in_tile.pkey)
INSERT INTO const_nodes(node_pkey, net_name)
SELECT DISTINCT
  wire_info.node_pkey,
CASE
  WHEN wire_info.name LIKE "GND_WIRE%" THEN "GND"
  WHEN wire_info.name LIKE "VCC_WIRE%" THEN "VCC"
  ELSE "unknown"
END
FROM
  wire_info
INNER JOIN
  node ON wire_info.node_pkey == node.pkey
WHERE
  wire_info.name LIKE "GND_WIRE%" OR wire_info.name LIKE "VCC_WIRE%"
        """
    )


def classify_const_nodes(conn):
    """
    Force classification of all const nodes
    """
    c = conn.cursor()
    c.execute(
        """
UPDATE
  node
SET
  classification = ?
WHERE
  number_pips > 0
AND
  pkey
IN (
  SELECT
    node_pkey
  FROM
    const_nodes
)
        """, (NodeClassification.EDGES_TO_CHANNEL.value, )
    )

    c.execute("""COMMIT TRANSACTION""")


# =============================================================================

# A set of synthetic tiles to be added
SYNTHETIC_TILES = {}

TILES_TO_MERGE = {}

TILES_TO_SPLIT = {}

TILE_SPLIT_STYLES = {}

# =============================================================================


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        '--db_root', help='Project U-Ray Database', required=True
    )
    parser.add_argument('--part', help='FPGA part', required=True)
    parser.add_argument(
        '--grid_limit',
        help='Tile grid range to import as <xmin>,<ymin>,<xmax>,<ymax>',
        type=str,
        default=None,
        required=False
    )
    parser.add_argument(
        '--connection_database', help='Connection database', required=True
    )
    parser.add_argument(
        '--grid_map_output',
        help='Location of the grid map output',
        required=True
    )

    args = parser.parse_args()

    grid_limit = None
    if args.grid_limit is not None:
        grid_limit = tuple([int(pos) for pos in args.grid_limit.split(",")])
        assert len(grid_limit) == 4, grid_limit
    print("Grid limit:", grid_limit)

    if os.path.exists(args.connection_database):
        os.remove(args.connection_database)

    with DatabaseCache(args.connection_database) as conn:
        create_tables(conn)

        print("{}: About to load database".format(datetime.datetime.now()))
        db = prjuray.db.Database(args.db_root, args.part)
        grid = db.grid()

        get_switch, get_switch_timing = create_get_switch(conn, get_pip_timing)

        import_phy_grid(
            db, grid, conn, get_switch, get_switch_timing, get_site_pin_timing,
            grid_limit
        )

        segment_wire_map = SegmentWireMap(default_segment="unknown", db=db)
        import_segments(conn, db, segment_wire_map)
        print("{}: Initial database formed".format(datetime.datetime.now()))
        import_nodes(db, grid, conn, grid_limit)
        print("{}: Connections made".format(datetime.datetime.now()))
        count_sites_and_pips_on_nodes(conn)
        print("{}: Counted sites and pips".format(datetime.datetime.now()))
        classify_nodes(conn, get_switch_timing, check_pip_for_direct)
        identify_const_nodes(conn)
        classify_const_nodes(conn)
        print("{}: Nodes classified".format(datetime.datetime.now()))
        with open(args.grid_map_output, 'w') as f:
            create_vpr_grid(
                conn, SYNTHETIC_TILES, TILES_TO_MERGE, TILES_TO_SPLIT,
                TILE_SPLIT_STYLES, f
            )
        print("{}: VPR grid created".format(datetime.datetime.now()))
        vcc_track_pkey, gnd_track_pkey = form_tracks(conn, segment_wire_map)
        print("{}: Tracks formed".format(datetime.datetime.now()))
        connect_hardpins_to_constant_network(
            conn, vcc_track_pkey, gnd_track_pkey
        )
        print("{}: VCC/GND pins connected".format(datetime.datetime.now()))

        print(
            '{} Flushing database back to file "{}"'.format(
                datetime.datetime.now(), args.connection_database
            )
        )


if __name__ == '__main__':
    main()
