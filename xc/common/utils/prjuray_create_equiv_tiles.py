#!/usr/bin/env python3
"""
Import the top level tile interconnect information from Project U-Ray database
files.

The Project U-Ray specifies the connections between tiles and the connect
between tiles and their sites. prjuray_tile_import generates a VPR pb_type
that has the correct tile pin names to connect to the routing fabric, and
connects those tile pins to each site within the tile.

"""

import argparse
import sqlite3

import simplejson as json

import prjuray.site_type

from create_equiv_tiles import create_equiv_tiles

# =============================================================================

NORMALIZED_TILE_TYPES = {}
NORMALIZED_SITE_TYPES = {}

# =============================================================================


def main():
    parser = argparse.ArgumentParser(
        description=__doc__, fromfile_prefix_chars='@', prefix_chars='-~'
    )

    parser.add_argument(
        '--site_directory',
        required=True,
        help="""Diretory where sites are defined"""
    )

    parser.add_argument(
        '--output_directory',
        required=True,
        help="Directory to write output XML too.",
    )

    parser.add_argument(
        '--pin_assignments',
        required=True,
    )

    parser.add_argument(
        '--connection_database',
        required=True,
        help=(
            "Location of connection database to define this tile type.  " +
            "The tile will be defined by the sites and wires from the " +
            "connection database in lue of Project U-Ray."
        )
    )

    parser.add_argument(
        '--tile_types',
        required=True,
        help="Comma seperated list of tiles to create equivilance between."
    )

    parser.add_argument(
        '--pb_types',
        nargs='+',
        required=True,
        help=""
    )

    parser.add_argument(
        '--site_equivilances',
        help="Comma seperated list of site equivilances to apply."
    )

    args = parser.parse_args()

    with open(args.pin_assignments) as f:
        pin_assignments = json.load(f)

    with sqlite3.connect("file:{}?mode=ro".format(args.connection_database),
                         uri=True) as conn:

        create_equiv_tiles(
            args,
            conn,
            pin_assignments,
            NORMALIZED_TILE_TYPES,
            NORMALIZED_SITE_TYPES,
            prjuray.site_type.SitePinDirection
        )


if __name__ == '__main__':
    main()
