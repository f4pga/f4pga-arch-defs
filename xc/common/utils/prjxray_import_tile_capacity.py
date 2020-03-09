""" Generates project xray. """
import argparse
import json
import prjxray.db
from prjxray.site_type import SitePinDirection
from lib.pb_type_xml import (
    start_pb_type, add_vpr_tile_prefix, add_tile_direct, object_ref,
    add_switchblock_locations
)
import lxml.etree as ET


def main():
    parser = argparse.ArgumentParser(description=__doc__)

    parser.add_argument('--db_root', required=True)
    parser.add_argument('--part', required=True)
    parser.add_argument('--output_directory', required=True)
    parser.add_argument('--site_directory', required=True)
    parser.add_argument('--tile_type', required=True)
    parser.add_argument('--pb_type', required=True)
    parser.add_argument('--pin_assignments', required=True)
    parser.add_argument('--site_coords', required=True)

    args = parser.parse_args()

    with open(args.pin_assignments) as f:
        pin_assignments = json.load(f)

    db = prjxray.db.Database(args.db_root, args.part)
    tile_type = db.get_tile_type(args.tile_type)

    input_wires = set()
    output_wires = set()

    sites = []

    for site in tile_type.get_sites():
        if site.type != args.pb_type:
            continue

        site_type = db.get_site_type(site.type)
        sites.append(site)

        for site_pin in site.site_pins:
            if site_type.get_site_pin(
                    site_pin.name).direction == SitePinDirection.IN:
                input_wires.add(site_pin.wire)
            elif site_type.get_site_pin(
                    site_pin.name).direction == SitePinDirection.OUT:
                output_wires.add(site_pin.wire)
            else:
                assert False, site_pin

    sites.sort(key=lambda site: (site.x, site.y))

    tile_xml = start_pb_type(
        args.tile_type,
        pin_assignments,
        input_wires,
        output_wires,
        root_pb_type=True,
        root_tag='tile',
    )

    tile_xml.attrib['capacity'] = str(len(sites))
    tile_xml.attrib['capacity_type'] = "explicit"

    equivalent_sites_xml = ET.Element('equivalent_sites')

    site_xml = ET.Element(
        'site', {
            'pb_type': add_vpr_tile_prefix(site.type),
            'pin_mapping': 'custom'
        }
    )
    for site_idx, site in enumerate(sites):
        if site.type != args.pb_type:
            continue

        for site_pin in site.site_pins:
            add_tile_direct(
                site_xml,
                tile=object_ref(
                    add_vpr_tile_prefix(args.tile_type),
                    site_pin.wire,
                ),
                pb_type=object_ref(
                    pb_name=add_vpr_tile_prefix(site.type),
                    pb_idx=site_idx,
                    pin_name=site_pin.name,
                ),
            )

    equivalent_sites_xml.append(site_xml)
    tile_xml.append(equivalent_sites_xml)
    add_switchblock_locations(tile_xml)

    with open('{}/{}.tile.xml'.format(args.output_directory,
                                      args.tile_type.lower()), 'w') as f:
        tile_str = ET.tostring(tile_xml, pretty_print=True).decode('utf-8')
        f.write(tile_str)


if __name__ == "__main__":
    main()
