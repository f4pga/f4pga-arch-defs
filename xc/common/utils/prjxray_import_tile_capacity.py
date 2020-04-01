""" Generates project xray. """
import argparse
import json
import prjxray.db
from prjxray.site_type import SitePinDirection
from lib.pb_type_xml import start_tile, add_switchblock_locations
import lxml.etree as ET


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

    db = prjxray.db.Database(args.db_root, args.part)
    tile_type = db.get_tile_type(args.tile_type)

    sites = {}

    pb_types = args.pb_types.split(',')

    for pb_type in pb_types:
        sites[pb_type] = []

    for site in tile_type.get_sites():
        if site.type not in pb_types:
            continue

        site_type = db.get_site_type(site.type)
        input_wires, output_wires = get_wires(site, site_type)

        sites[site.type].append((site, input_wires, output_wires))

    tile_xml = start_tile(
        args.tile_type,
        pin_assignments,
        sites=sites,
    )

    add_switchblock_locations(tile_xml)

    with open('{}/{}.tile.xml'.format(args.output_directory,
                                      args.tile_type.lower()), 'w') as f:
        tile_str = ET.tostring(tile_xml, pretty_print=True).decode('utf-8')
        f.write(tile_str)


if __name__ == "__main__":
    main()
