""" Convert a PCF file into a VPR io.place file. """
from __future__ import print_function
import argparse
import csv
import json
import sys
import vpr_place_constraints
import sqlite3
from lib.parse_pcf import parse_simple_pcf

def get_vpr_coords_from_site_name(conn, site_name):
    cur = conn.cursor()
    cur.execute(
        """
SELECT DISTINCT tile.grid_x, tile.grid_y
FROM site_instance
INNER JOIN wire_in_tile
ON
  site_instance.site_pkey = wire_in_tile.site_pkey
INNER JOIN wire
ON
  wire.phy_tile_pkey = site_instance.phy_tile_pkey
AND
  wire_in_tile.pkey = wire.wire_in_tile_pkey
INNER JOIN tile
ON tile.pkey = wire.tile_pkey
WHERE
  site_instance.name = ?;""", (site_name, )
    )

    results = cur.fetchall()
    assert len(results) == 1
    return results[0]

def main():
    parser = argparse.ArgumentParser(
        description='Convert a PCF file into a VPR io.place file.'
    )
    parser.add_argument(
        "--output",
        '-o',
        "-O",
        type=argparse.FileType('a'),
        default=sys.stdout,
        help='The output constraints place file'
    )
    parser.add_argument(
        "--net",
        '-n',
        type=argparse.FileType('r'),
        required=True,
        help='top.net file'
    )
    parser.add_argument(
        '--connection_database',
        help='Database of fabric connectivity',
        required=True
    )

    args = parser.parse_args()

    place_constraints = vpr_io_place.PlaceConstraints()
    place_constraints.load_loc_sites_from_net_file(args.net)

    for loc in place_constraints.get_loc_sites():
        print(get_vpr_coords_from_site_name(conn, loc)

    io_place.output_io_place(args.output)

if __name__ == '__main__':
    main()
