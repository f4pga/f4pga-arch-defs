#! /usr/bin/env python3
""" Tool generate a pin map CSV from channels.db and a *_package_pins.csv for pin placement. """
from __future__ import print_function
import argparse
import sys
import csv
import sqlite3


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
    assert len(results) == 1, site_name
    return results[0]


def main():
    parser = argparse.ArgumentParser(description='Creates a pin map CSV.')
    parser.add_argument(
        "--output",
        type=argparse.FileType('w'),
        default=sys.stdout,
        help='The output pin map CSV file'
    )
    parser.add_argument(
        '--connection_database',
        help='Database of fabric connectivity',
        required=True
    )
    parser.add_argument(
        "--package_pins",
        type=argparse.FileType('r'),
        required=True,
        help='Map listing relationship between pads and sites.',
    )

    args = parser.parse_args()

    fieldnames = [
        'name', 'x', 'y', 'z', 'is_clock', 'is_input', 'is_output', 'iob'
    ]
    writer = csv.DictWriter(args.output, fieldnames=fieldnames)

    writer.writeheader()
    with sqlite3.connect(args.connection_database) as conn:
        for l in csv.DictReader(args.package_pins):
            loc = get_vpr_coords_from_site_name(conn, l['site'])
            if loc is not None:
                writer.writerow(
                    dict(
                        name=l['pin'],
                        x=loc[0],
                        y=loc[1],
                        z=0,
                        is_clock=1,
                        is_input=1,
                        is_output=1,
                        iob=l['site'],
                    )
                )


if __name__ == '__main__':
    main()
