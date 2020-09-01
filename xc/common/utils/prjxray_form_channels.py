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
prjxray_assign_tile_pin_direction.


"""
import argparse
import os
import datetime

import prjxray.db
import prjxray.tile
from prjxray.timing import PvtCorner

from lib.connection_database import create_tables
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

from prjxray_define_segments import SegmentWireMap

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

    if isinstance(site_pin.timing, prjxray.tile.OutPinTiming):
        # milliOhms -> Ohms
        R = site_pin.timing.drive_resistance / 1e3
    elif isinstance(site_pin.timing, prjxray.tile.InPinTiming):
        # microFarads -> Farads
        C = site_pin.timing.capacitance / 1e6
    else:
        assert False, site_pin

    return R, C, Tdel


def check_pip_for_direct(pip_name):
    """
    Returns true when the given pip should be modeled as a direct connection
    """

    # A solution for:
    # https://github.com/SymbiFlow/symbiflow-arch-defs/issues/1033
    if "PADOUT0" in pip_name and "DIFFI_IN1" in pip_name:
        return True
    if "PADOUT1" in pip_name and "DIFFI_IN0" in pip_name:
        return True

    return False


def connect_hardpins_to_constant_network(conn, vcc_track_pkey, gnd_track_pkey):
    """ Connect TIEOFF HARD1 and HARD0 pins.

    Update nodes connected to to HARD1 or HARD0 pins to point to the new
    VCC or GND track.  This should connect the pips to the constant
    network instead of the TIEOFF site.
    """

    cur = conn.cursor()
    cur.execute(
        """
SELECT pkey FROM site_type WHERE name = ?
""", ("TIEOFF", )
    )
    results = cur.fetchall()
    assert len(results) == 1, results
    tieoff_site_type_pkey = results[0][0]

    cur.execute(
        """
SELECT pkey FROM site_pin WHERE site_type_pkey = ? and name = ?
""", (tieoff_site_type_pkey, "HARD1")
    )
    vcc_site_pin_pkey = cur.fetchone()[0]
    cur.execute(
        """
SELECT pkey FROM wire_in_tile WHERE site_pin_pkey = ?
""", (vcc_site_pin_pkey, )
    )

    cur.execute(
        """
SELECT pkey FROM wire_in_tile WHERE site_pin_pkey = ?
""", (vcc_site_pin_pkey, )
    )

    write_cur = conn.cursor()
    write_cur.execute("""BEGIN EXCLUSIVE TRANSACTION;""")

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

    cur.execute(
        """
SELECT pkey FROM site_pin WHERE site_type_pkey = ? and name = ?
""", (tieoff_site_type_pkey, "HARD0")
    )
    gnd_site_pin_pkey = cur.fetchone()[0]

    cur.execute(
        """
SELECT pkey FROM wire_in_tile WHERE site_pin_pkey = ?
""", (gnd_site_pin_pkey, )
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

# =============================================================================


# A set of synthetic tiles to be added
SYNTHETIC_TILES = {
    'SLICEL',
    'SLICEM',
    'LIOPAD_M',
    'LIOPAD_S',
    'LIOPAD_SING',
    'RIOPAD_M',
    'RIOPAD_S',
    'RIOPAD_SING',
}

TILES_TO_MERGE = {
    'LIOB33_SING': tile_splitter.grid.EAST,
    'LIOB33': tile_splitter.grid.EAST,
    'RIOB33_SING': tile_splitter.grid.WEST,
    'RIOB33': tile_splitter.grid.WEST,
}

TILES_TO_SPLIT = {
    'LIOI3': tile_splitter.grid.NORTH,
    'LIOI3_TBYTESRC': tile_splitter.grid.NORTH,
    'LIOI3_TBYTETERM': tile_splitter.grid.NORTH,
    'LIOI3_SING': tile_splitter.grid.NORTH,
    'RIOI3': tile_splitter.grid.NORTH,
    'RIOI3_TBYTESRC': tile_splitter.grid.NORTH,
    'RIOI3_TBYTETERM': tile_splitter.grid.NORTH,
    'RIOI3_SING': tile_splitter.grid.NORTH,
}

LIOPAD_MS_SPLIT = {
    1: 'LIOPAD_M',
    0: 'LIOPAD_S',
}
RIOPAD_MS_SPLIT = {
    1: 'RIOPAD_M',
    0: 'RIOPAD_S',
}

TILE_SPLIT_STYLES = {
    'LIOI3': ('y_split', LIOPAD_MS_SPLIT),
    'LIOI3_TBYTESRC': ('y_split', LIOPAD_MS_SPLIT),
    'LIOI3_TBYTETERM': ('y_split', LIOPAD_MS_SPLIT),
    'RIOI3': ('y_split', RIOPAD_MS_SPLIT),
    'RIOI3_TBYTESRC': ('y_split', RIOPAD_MS_SPLIT),
    'RIOI3_TBYTETERM': ('y_split', RIOPAD_MS_SPLIT),
    'LIOI3_SING': ('y_split', {
        0: 'LIOPAD_SING'
    }),
    'RIOI3_SING': ('y_split', {
        0: 'RIOPAD_SING'
    }),
}

# =============================================================================


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        '--db_root',
        help='Project X-Ray Database',
        required=True
    )
    parser.add_argument(
        '--part',
        help='FPGA part',
        required=True
    )
    parser.add_argument(
        '--connection_database',
        help='Connection database',
        required=True
    )
    parser.add_argument(
        '--grid_map_output',
        help='Location of the grid map output',
        required=True
    )

    args = parser.parse_args()

    if os.path.exists(args.connection_database):
        os.remove(args.connection_database)

    with DatabaseCache(args.connection_database) as conn:
        create_tables(conn)

        print("{}: About to load database".format(datetime.datetime.now()))
        db = prjxray.db.Database(args.db_root, args.part)
        grid = db.grid()

        get_switch, get_switch_timing = create_get_switch(
            conn,
            get_pip_timing
        )

        import_phy_grid(db, grid, conn, get_switch, get_switch_timing, get_site_pin_timing)
        
        segment_wire_map = SegmentWireMap(default_segment="unknown", db=db)
        import_segments(conn, db, segment_wire_map)

        print("{}: Initial database formed".format(datetime.datetime.now()))
        import_nodes(db, grid, conn)
        print("{}: Connections made".format(datetime.datetime.now()))
        count_sites_and_pips_on_nodes(conn)
        print("{}: Counted sites and pips".format(datetime.datetime.now()))
        classify_nodes(conn, get_switch_timing, check_pip_for_direct)
        print("{}: Nodes classified".format(datetime.datetime.now()))
        with open(args.grid_map_output, 'w') as f:
            create_vpr_grid(
                conn,
                SYNTHETIC_TILES,
                TILES_TO_MERGE,
                TILES_TO_SPLIT,
                TILE_SPLIT_STYLES,
                f
            )
        print("{}: VPR grid created".format(datetime.datetime.now()))
        vcc_track_pkey, gnd_track_pkey = form_tracks(conn, segment_wire_map)
        print("{}: Tracks formed".format(datetime.datetime.now()))
        connect_hardpins_to_constant_network(conn, vcc_track_pkey, gnd_track_pkey)
        print("{}: VCC/GND pins connected".format(datetime.datetime.now()))

        print(
            '{} Flushing database back to file "{}"'.format(
                datetime.datetime.now(), args.connection_database
            )
        )


if __name__ == '__main__':
    main()
