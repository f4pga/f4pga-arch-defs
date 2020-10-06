#!/usr/bin/env python3
import argparse
import json

import prjuray.db
from prjuray.site_type import SitePinDirection

from import_tile_capacity import import_tile_capacity


def get_wires(site, site_type):
    """Get wires related to a site"""
    input_wires = set()
    output_wires = set()

    for site_pin in site.site_pins:
        if site_type.get_site_pin(
                site_pin.name).direction == SitePinDirection.IN:
            input_wires.add(site_pin.wire)
        elif site_type.get_site_pin(
                site_pin.name).direction == SitePinDirection.OUT:
            output_wires.add(site_pin.wire)
        else:
            assert False, site_pin

    return input_wires, output_wires


def main():
    parser = argparse.ArgumentParser(description=__doc__)

    parser.add_argument('--db_root', required=True)
    parser.add_argument('--part', required=True)
    parser.add_argument('--output_directory', required=True)
    parser.add_argument('--site_directory', required=True)
    parser.add_argument('--tile_type', required=True)
    parser.add_argument('--pb_types', required=True)
    parser.add_argument('--pin_assignments', required=True)

    args = parser.parse_args()

    with open(args.pin_assignments) as f:
        pin_assignments = json.load(f)

    db = prjuray.db.Database(args.db_root, args.part)
    tile_type = db.get_tile_type(args.tile_type)

    import_tile_capacity(args, db, pin_assignments, get_wires)


if __name__ == "__main__":
    main()
