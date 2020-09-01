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


def add_fake_site_hardpins(conn, get_switch_timing):
    """
    Adds fake site pins to be used for GND_WIRE* and VCC_WIRE*.
    """

    write_cur = conn.cursor()

    # Insert fake site pins for GND and VCC sources
    write_cur.execute(
        "INSERT INTO site_pin(name, site_type_pkey, direction) VALUES (\"GND\", NULL, \"output\")"
    )
    gnd_site_pin_pkey = write_cur.lastrowid

    write_cur.execute(
        "INSERT INTO site_pin(name, site_type_pkey, direction) VALUES (\"VCC\", NULL, \"output\")"
    )
    vcc_site_pin_pkey = write_cur.lastrowid

    # Create a switch for VCC and GND wires
    const_switch_pkey = get_switch_timing(
        is_pass_transistor=False,
        delay=0.0,
        internal_capacitance=0.0,
        drive_resistance=0.0,
    )

    # Assign GND_WIRE* and VCC_WIRE* to these site pins.
    write_cur.execute(
        """
UPDATE wire_in_tile SET site_pin_pkey = ?, site_pin_switch_pkey = ? WHERE name LIKE "GND_WIRE%"
        """, (gnd_site_pin_pkey, const_switch_pkey,)
        )

    write_cur.execute(
        """
UPDATE wire_in_tile SET site_pin_pkey = ?, site_pin_switch_pkey = ? WHERE name LIKE "VCC_WIRE%"
        """, (vcc_site_pin_pkey, const_switch_pkey,)
        )


# =============================================================================


# A set of synthetic tiles to be added
SYNTHETIC_TILES = {
}

TILES_TO_MERGE = {
}

TILES_TO_SPLIT = {
}

TILE_SPLIT_STYLES = {
}

# =============================================================================


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        '--db_root',
        help='Project U-Ray Database',
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
        db = prjuray.db.Database(args.db_root, args.part)
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
        #add_fake_site_hardpins(conn, get_switch_timing)
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
