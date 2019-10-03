#! /usr/bin/env python3
""" Tool generate a pin map CSV from channels.db and a *_package_pins.csv for pin placement. """
from __future__ import print_function
import argparse
import sys
import csv
import sqlite3


def get_vpr_coords_from_tile_name(conn, tile_name):
    cur = conn.cursor()
    loc = tile_name.split('_')[-1]
    cur.execute(
        """
        SELECT grid_x, grid_y FROM tile
          WHERE phy_tile_pkey =
            (SELECT pkey FROM phy_tile WHERE name like "%IOI%_" || ?);
        """, (loc, )
    )
    return cur.fetchone()


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
            loc = get_vpr_coords_from_tile_name(conn, l['tile'])
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
