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
import sys

import lxml.etree as ET

import prjuray.db
import prjuray.site_type

from tile_import import import_site_as_tile
from tile_import import import_tile_from_database
from tile_import import import_tile

XI_URL = "http://www.w3.org/2001/XInclude"


def main():
    parser = argparse.ArgumentParser(
        description=__doc__, fromfile_prefix_chars='@', prefix_chars='-~'
    )

    parser.add_argument('--db_root', help="""Project U-Ray database to use.""")

    parser.add_argument('--part', help="""FPGA part to use.""")

    parser.add_argument('--tile', help="""Tile to generate for""")

    parser.add_argument(
        '--site_directory', help="""Diretory where sites are defined"""
    )

    parser.add_argument(
        '--site_coords',
        type=str,
        default='X',
        help="""Specify which site coords to use ('X', 'Y' or 'XY')"""
    )

    parser.add_argument(
        '--output-pb-type',
        nargs='?',
        type=argparse.FileType('w'),
        default=sys.stdout,
        help="""File to write the output too."""
    )

    parser.add_argument(
        '--output-model',
        nargs='?',
        type=argparse.FileType('w'),
        default=sys.stdout,
        help="""File to write the output too."""
    )

    parser.add_argument(
        '--pin_assignments', required=True, type=argparse.FileType('r')
    )
    parser.add_argument(
        '--site_as_tile',
        action='store_true',
    )

    parser.add_argument(
        '--site_types',
        required=True,
        help="Comma seperated list of site types to include in this tile."
    )

    parser.add_argument(
        '--fused_sites',
        action='store_true',
        help="""
Typically a tile can treat the sites within the tile as independent.
For tiles where this is not true, fused sites only imports 1 primatative
for the entire tile, which should be named the same as the tile type."""
    )

    parser.add_argument(
        '--connection_database',
        help="""
Location of connection database to define this tile type.
The tile will be defined by the sites and wires from the
connection database in lue of Project X-Ray."""
    )

    parser.add_argument(
        '--filter_x', help="Filter imported sites by their x coordinate."
    )

    parser.add_argument(
        '--no_fasm_prefix',
        action="store_true",
        help="""Do not insert fasm prefix to the metadata."""
    )

    args = parser.parse_args()

    db = prjuray.db.Database(args.db_root, args.part)

    ET.register_namespace('xi', XI_URL)
    if args.site_as_tile:
        assert not args.fused_sites
        import_site_as_tile(db, args, prjuray.site_type.SitePinDirection)
    elif args.connection_database:
        with sqlite3.connect("file:{}?mode=ro".format(
                args.connection_database), uri=True) as conn:
            import_tile_from_database(conn, args, prjuray.site_type.SitePinDirection)
    else:
        import_tile(db, args, prjuray.site_type.SitePinDirection)


if __name__ == '__main__':
    main()
