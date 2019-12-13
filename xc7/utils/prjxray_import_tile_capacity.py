""" Generates project xray. """
import argparse
import json
import prjxray.db
from prjxray.site_type import SitePinDirection

import lxml.etree as ET

XI_URL = "http://www.w3.org/2001/XInclude"
XI_INCLUDE = "{%s}include" % XI_URL

VPR_TILE_PREFIX = 'BLK-TL-'


def add_vpr_tile_prefix(tile):
    """ Add tile prefix.

    This avoids namespace collision when embedding a site (e.g. SLICEL) as a
    tile.
    """
    return VPR_TILE_PREFIX + tile


def object_ref(pb_name, pin_name, pb_idx=None, pin_idx=None):
    pb_addr = ''
    if pb_idx is not None:
        pb_addr = '[{}]'.format(pb_idx)

    pin_addr = ''
    if pin_idx is not None:
        pin_addr = '[{}]'.format(pin_idx)

    return '{}{}.{}{}'.format(pb_name, pb_addr, pin_name, pin_addr)


def add_pinlocations(tile_name, xml, fc_xml, pin_assignments, wires):
    """ Adds the pin locations.

    It requires the ports of the physical tile which are retrieved
    by the pb_type.xml definition.
    """
    pinlocations_xml = ET.SubElement(
        xml, 'pinlocations', {
            'pattern': 'custom',
        }
    )

    sides = {}
    for pin in wires:
        for side in pin_assignments['pin_directions'][tile_name][pin]:
            if side not in sides:
                sides[side] = []

            sides[side].append(object_ref(add_vpr_tile_prefix(tile_name), pin))

    for side, pins in sides.items():
        ET.SubElement(pinlocations_xml, 'loc', {
            'side': side.lower(),
        }).text = ' '.join(pins)

    direct_pins = set()
    for direct in pin_assignments['direct_connections']:
        if direct['from_pin'].split('.')[0] == tile_name:
            direct_pins.add(direct['from_pin'].split('.')[1])

        if direct['to_pin'].split('.')[0] == tile_name:
            direct_pins.add(direct['to_pin'].split('.')[1])

    for fc_override in direct_pins:
        ET.SubElement(
            fc_xml, 'fc_override', {
                'fc_type': 'frac',
                'fc_val': '0.0',
                'port_name': fc_override,
            }
        )


def add_fc(xml):
    fc_xml = ET.SubElement(
        xml, 'fc', {
            'in_type': 'abs',
            'in_val': '2',
            'out_type': 'abs',
            'out_val': '2',
        }
    )

    return fc_xml


def add_switchblock_locations(xml):
    ET.SubElement(xml, 'switchblock_locations', {
        'pattern': 'all',
    })


def start_pb_type(
        tile_name,
        pin_assignments,
        input_wires,
        output_wires,
        root_pb_type,
        root_tag='pb_type'
):
    """ Starts a pb_type by adding input, clock and output tags. """
    pb_type_xml = ET.Element(
        root_tag,
        {
            'name': add_vpr_tile_prefix(tile_name),
        },
        nsmap={'xi': XI_URL},
    )

    pb_type_xml.append(ET.Comment(" Tile Inputs "))

    # Input definitions for the TILE
    for name in sorted(input_wires):
        input_type = 'input'

        if name.startswith('CLK_BUFG_'):
            if name.endswith('I0') or name.endswith('I1'):
                input_type = 'clock'
        elif 'CLK' in name:
            input_type = 'clock'

        ET.SubElement(
            pb_type_xml,
            input_type,
            {
                'name': name,
                'num_pins': '1'
            },
        )

    pb_type_xml.append(ET.Comment(" Tile Outputs "))
    for name in sorted(output_wires):
        # Output definitions for the TILE
        ET.SubElement(
            pb_type_xml,
            'output',
            {
                'name': name,
                'num_pins': '1'
            },
        )

    if root_pb_type:
        fc_xml = add_fc(pb_type_xml)

        add_pinlocations(
            tile_name, pb_type_xml, fc_xml, pin_assignments,
            set(input_wires) | set(output_wires)
        )

    pb_type_xml.append(ET.Comment(" Internal Sites "))

    return pb_type_xml


def add_tile_direct(xml, tile, pb_type):
    """ Add a direct tag to the interconnect_xml. """
    ET.SubElement(xml, 'direct', {'from': tile, 'to': pb_type})


def main():
    parser = argparse.ArgumentParser(description=__doc__)

    parser.add_argument('--db_root', required=True)
    parser.add_argument('--output_directory', required=True)
    parser.add_argument('--site_directory', required=True)
    parser.add_argument('--tile_type', required=True)
    parser.add_argument('--pb_type', required=True)
    parser.add_argument('--pin_assignments', required=True)
    parser.add_argument('--site_coords', required=True)

    args = parser.parse_args()

    with open(args.pin_assignments) as f:
        pin_assignments = json.load(f)

    db = prjxray.db.Database(args.db_root)
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
