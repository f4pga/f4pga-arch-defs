#! /usr/bin/env python3
""" Tool generate a pin map CSV from channels.db and a *_package_pins.csv for pin placement. """
from __future__ import print_function
import argparse
import sys
import csv
import sqlite3
import json

import prjxray.db


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
    if len(results) == 1:
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
        '--db_root',
        help='Database of fabric connectivity',
        required=True
    )
    parser.add_argument('--part', required=True, help="FPGA part")
    parser.add_argument(
        "--synth_tiles",
        type=argparse.FileType('r'),
        required=False,
        help='Pin map synth_tiles JSON file'
    )
    parser.add_argument(
        "--overlay",
        action='store_true',
        required=False,
        help='Whether the pin map should contain a mix of real and synth IOs'
    )
    parser.add_argument(
        "--package_pins",
        type=argparse.FileType('r'),
        required=True,
        help='Map listing relationship between pads and sites.'
    )

    args = parser.parse_args()

    db = prjxray.db.Database(args.db_root, args.part)
    grid = db.grid()

    pin_to_iob = {}
    with sqlite3.connect(args.connection_database) as conn:
        for line in csv.DictReader(args.package_pins):
            assert line['pin'] not in pin_to_iob
            site = line['site']
            loc = get_vpr_coords_from_site_name(conn, site)
            gridinfo = grid.gridinfo_at_tilename(line['tile'])
            sites = list(gridinfo.sites.keys())
            loc = loc + (sites.index(site), )

            if loc:
                pin_to_iob[line['pin']] = (line['site'], loc)

    args.package_pins.seek(0)
    if args.synth_tiles:
        synth_tiles = json.load(args.synth_tiles)

    fieldnames = [
        'name', 'x', 'y', 'z', 'is_clock', 'is_input', 'is_output', 'iob',
        'real_io_assoc'
    ]
    writer = csv.DictWriter(args.output, fieldnames=fieldnames)

    writer.writeheader()
    synth_tile_pads = set()
    if args.synth_tiles:
        for synth_tile in synth_tiles['tiles'].values():
            for pin in synth_tile['pins']:
                assert pin['pad'] not in synth_tile_pads, pin['pad']
                synth_tile_pads.add(pin['pad'])
                real_io_assoc = pin['pad'] in pin_to_iob
                x = synth_tile['loc'][0]
                y = synth_tile['loc'][1]
                z = pin['z_loc']
                writer.writerow(
                    dict(
                        name=pin['pad'],
                        x=x,
                        y=y,
                        z=z,
                        is_clock=1 if pin['is_clock'] else 0,
                        is_input=0 if pin['port_type'] == 'input' else 1,
                        is_output=0 if pin['port_type'] == 'output' else 1,
                        iob=pin_to_iob[pin['pad']][0] if real_io_assoc else '',
                        real_io_assoc=real_io_assoc,
                    )
                )

    if not args.synth_tiles or args.overlay:
        for line in csv.DictReader(args.package_pins):

            # Skip PS7 MIO and DDR pads as they are not routable
            if line['tile'].startswith('PSS'):
                continue

            if line['pin'] in synth_tile_pads:
                continue

            loc = pin_to_iob[line['pin']][1]
            if loc is not None:
                z = 0 if len(loc) == 2 else loc[2]
                writer.writerow(
                    dict(
                        name=line['pin'],
                        x=loc[0],
                        y=loc[1],
                        z=loc[2],
                        is_clock=1,
                        is_input=1,
                        is_output=1,
                        iob=line['site'],
                        real_io_assoc='True',
                    )
                )


if __name__ == '__main__':
    main()
