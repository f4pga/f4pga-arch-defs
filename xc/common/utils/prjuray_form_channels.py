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

import tile_splitter.grid

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


def yield_downstream_nodes(conn, node_pkey):
    """
    For the given node pkey yields pkeys of all its immediate downstream nodes.
    """

    c = conn.cursor()
    for (node, ) in c.execute("""
WITH wire_in_node(
  wire_pkey
) AS (
  SELECT
    wire.pkey
  FROM
    wire
  WHERE
    wire.node_pkey = ?
), downstream_wire_in_tile(
  wire_pkey, phy_tile_pkey, wire_in_tile_pkey
) AS (
  SELECT
    wire.pkey,
    wire.phy_tile_pkey,
    pip_in_tile.dest_wire_in_tile_pkey
  FROM
    wire
  INNER JOIN
    pip_in_tile
  ON
    pip_in_tile.is_pseudo == 0 AND
    pip_in_tile.src_wire_in_tile_pkey == wire.wire_in_tile_pkey
)
SELECT
  wire.node_pkey
FROM
  wire
INNER JOIN
  downstream_wire_in_tile
ON
  downstream_wire_in_tile.phy_tile_pkey == wire.phy_tile_pkey AND
  downstream_wire_in_tile.wire_in_tile_pkey == wire.wire_in_tile_pkey
WHERE
  downstream_wire_in_tile.wire_pkey IN wire_in_node
        """, (node_pkey, )):
        yield node


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
    Returns true when the given pip should be modeled as a direct connection.
    Returns false otherwise.
    """
    return False


def connect_hardpins_to_constant_network(conn, vcc_track_pkey, gnd_track_pkey):
    """
    Connect all const source nodes to global VCC or GND tracks.

    This function identifies const nodes by looking for wires name "GND_WIRE*"
    and "VCC_WIRE*" that belong to them. All identified nodes are assigned
    a new track pkey that correspond to either global VCC or GND signal track.
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
    Creates a new table for const nodes named "const _nodes". Identifies them
    and inserts their pkeys along with const signal name to the table.

    The identification is based on specific wire membership. Constant 0 source
    nodes have at least one wire named "GND_WIRE*" while constant 1 nodes have
    at leas one "VCC_WIRE*" wire.
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
    Fixes classification of constant nodes.

    In US/US+ const source nodes are not attached to TIEOFF sites as in
    7-series. This causes them to be classified incorrectly as NULL  because
    they appear disconnected. The algorithm implemented in this function
    re-evaluates classification of these nodes.

    Const nodes pkeys are stored in "const_nodes" table created and populated
    in identify_const_nodes() function. The algorithm is based on recursive
    node tree traversal which begins on a const node and finishes either on
    a CHANNEL node or a node that connects to a site. Only const nodes that
    don't connect to any site directly and have at least 1 PIP are considered
    to be valid begin points. As the result all nodes in the tree get CHANNEL
    classification except nodes that connect to sites which get classified as
    EDGES_TO_CHANNEL. Node classification is updated in the "node" table.
    """

    # Const nodes that have no PIPs should already be classified as NULL.

    # Recursive walk utility function
    def walk(node_pkey, stack, paths):
        """
        Walk recursively until a site is reached. Store path(s).
        """
        c2 = conn.cursor()

        for node in yield_downstream_nodes(conn, node_pkey):
            c2.execute(
                "SELECT classification, site_wire_pkey FROM node WHERE pkey = ?",
                (node, )
            )
            classification, site_wire_pkey = c2.fetchone()

            # We've hit either a site or a channel
            if site_wire_pkey is not None or classification != NodeClassification.NULL.value:

                # Mark all nodes currently on stack as CHANNEL
                path = [
                    (
                        n,
                        NodeClassification.CHANNEL.value,
                    ) for n in stack
                ]

                # Mark the last one appripriately
                if site_wire_pkey is None:
                    path.append((
                        node,
                        NodeClassification.CHANNEL.value,
                    ))
                else:
                    path.append(
                        (
                            node,
                            NodeClassification.EDGES_TO_CHANNEL.value,
                        )
                    )

                paths.append(path)

            # Recurse
            else:
                stack.append(node)
                walk(node, stack, paths)
                stack = stack[:-1]

    # Const nodes that can reach either other CHANNEL nodes or site pins may
    # have been classified as NULL. Fix it here by starting from each NULL
    # const node that has PIPs and walking until a CHANNEL or site is found.
    node_classification = {
        NodeClassification.CHANNEL.value: set(),
        NodeClassification.EDGES_TO_CHANNEL.value: set(),
    }

    c = conn.cursor()
    for (node_pkey, ) in c.execute("""
SELECT
  pkey
FROM
  node
WHERE
  number_pips > 0 AND
  site_wire_pkey IS NULL AND
  classification = ?
AND
  pkey
IN (
  SELECT
    node_pkey
  FROM
    const_nodes
)
        """, (NodeClassification.NULL.value, )):

        # Walk, collect paths to sites
        paths = []
        stack = [node_pkey]
        walk(node_pkey, stack, paths)

        # Collect nodes
        for path in paths:
            for node, classification in path:
                node_classification[classification].add(node)

    # Update classifications
    c.execute("""BEGIN EXCLUSIVE TRANSACTION;""")

    for classification, nodes in node_classification.items():
        for node in nodes:
            c.execute(
                """
UPDATE
  node
SET
  classification = ?
WHERE
  pkey = ?
            """, (
                    classification,
                    node,
                )
            )

    c.execute("""COMMIT TRANSACTION;""")


# =============================================================================

# A set of synthetic tiles to be added
SYNTHETIC_TILES = {
    'HDIO_TOP_M',
    'HDIO_TOP_S',
    'HDIO_BOT_M',
    'HDIO_BOT_S',
}

TILES_TO_MERGE = {}

TILES_TO_SPLIT = {
}

TILE_SPLIT_STYLES = {
    'HDIO_TOP_RIGHT': tile_splitter.grid.NORTH,
    'HDIO_BOT_RIGHT': tile_splitter.grid.NORTH,
}

HDIO_TOP_SPLIT = {
   2:
    ('HDIO_TOP_M', ('HDIOB_M_X0Y0', 'HDIOLOGIC_M_X0Y0', 'HDIOBDIFFINBUF_X0Y0')),
   4:
    ('HDIO_TOP_S', ('HDIOB_S_X0Y1', 'HDIOLOGIC_S_X0Y0')),
   6:
    ('HDIO_TOP_M', ('HDIOB_M_X0Y2', 'HDIOLOGIC_M_X0Y1', 'HDIOBDIFFINBUF_X0Y1')),
   8:
    ('HDIO_TOP_S', ('HDIOB_S_X0Y3', 'HDIOLOGIC_S_X0Y1')),
   10:
    ('HDIO_TOP_M', ('HDIOB_M_X0Y4', 'HDIOLOGIC_M_X0Y2', 'HDIOBDIFFINBUF_X0Y2')),
   12:
    ('HDIO_TOP_S', ('HDIOB_S_X0Y5', 'HDIOLOGIC_S_X0Y2')),
   14:
    ('HDIO_TOP_M', ('HDIOB_M_X0Y6', 'HDIOLOGIC_M_X0Y3', 'HDIOBDIFFINBUF_X0Y3')),
   16:
    ('HDIO_TOP_S', ('HDIOB_S_X0Y7', 'HDIOLOGIC_S_X0Y3')),
   18:
    ('HDIO_TOP_M', ('HDIOB_M_X0Y8', 'HDIOLOGIC_M_X0Y4', 'HDIOBDIFFINBUF_X0Y4')),
   20:
    ('HDIO_TOP_S', ('HDIOB_S_X0Y9', 'HDIOLOGIC_S_X0Y4')),
   22:
    ('HDIO_TOP_M', ('HDIOB_M_X0Y10', 'HDIOLOGIC_M_X0Y5', 'HDIOBDIFFINBUF_X0Y5')),
   24:
    ('HDIO_TOP_S', ('HDIOB_S_X0Y11', 'HDIOLOGIC_S_X0Y5')),
}

HDIO_BOT_SPLIT = {
   2:
    ('HDIO_BOT_M', ('HDIOB_M_X0Y0', 'HDIOLOGIC_M_X0Y0', 'HDIOBDIFFINBUF_X0Y0')),
   4:
    ('HDIO_BOT_S', ('HDIOB_S_X0Y1', 'HDIOLOGIC_S_X0Y0')),
   6:
    ('HDIO_BOT_M', ('HDIOB_M_X0Y2', 'HDIOLOGIC_M_X0Y1', 'HDIOBDIFFINBUF_X0Y1')),
   8:
    ('HDIO_BOT_S', ('HDIOB_S_X0Y3', 'HDIOLOGIC_S_X0Y1')),
   10:
    ('HDIO_BOT_M', ('HDIOB_M_X0Y4', 'HDIOLOGIC_M_X0Y2', 'HDIOBDIFFINBUF_X0Y2')),
   12:
    ('HDIO_BOT_S', ('HDIOB_S_X0Y5', 'HDIOLOGIC_S_X0Y2')),
   14:
    ('HDIO_BOT_M', ('HDIOB_M_X0Y6', 'HDIOLOGIC_M_X0Y3', 'HDIOBDIFFINBUF_X0Y3')),
   16:
    ('HDIO_BOT_S', ('HDIOB_S_X0Y7', 'HDIOLOGIC_S_X0Y3')),
   18:
    ('HDIO_BOT_M', ('HDIOB_M_X0Y8', 'HDIOLOGIC_M_X0Y4', 'HDIOBDIFFINBUF_X0Y4')),
   20:
    ('HDIO_BOT_S', ('HDIOB_S_X0Y9', 'HDIOLOGIC_S_X0Y4')),
   22:
    ('HDIO_BOT_M', ('HDIOB_M_X0Y10', 'HDIOLOGIC_M_X0Y5', 'HDIOBDIFFINBUF_X0Y5')),
   24:
    ('HDIO_BOT_S', ('HDIOB_S_X0Y11', 'HDIOLOGIC_S_X0Y5')),
}

TILE_SPLIT_STYLES = {
    'HDIO_TOP_RIGHT': ('explicit', HDIO_TOP_SPLIT),
    'HDIO_BOT_RIGHT': ('explicit', HDIO_BOT_SPLIT),
            }

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
