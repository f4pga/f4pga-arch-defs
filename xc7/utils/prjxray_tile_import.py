#!/usr/bin/env python3
"""
Import the top level tile interconnect information from Project X-Ray database
files.

The Project X-Ray specifies the connections between tiles and the connect
between tiles and their sites.  prjxray_tile_import generates a VPR pb_type
that has the correct tile pin names to connect to the routing fabric, and
connects those tile pins to each site within the tile.

"""

from __future__ import print_function
import argparse
import os
import sys
import prjxray.db
import prjxray.site_type
import os.path
import simplejson as json
import re

import lxml.etree as ET


def find_port(pin_name, ports):
    if pin_name in ports:
        return {
            'pin_name': pin_name,
            'pin_idx': None,
        }

    # Find trailing digits, which are assumed to be pin indicies, example:
    # ADDRARDADDR13
    m = re.search('([0-9]+)$', pin_name)
    if m is None:
        return None

    prefix = pin_name[:-len(m.group(1))]
    prefix_pin_idx = int(m.group(1))

    if prefix in ports and prefix_pin_idx < ports[prefix]:
        return {
            'pin_name': prefix,
            'pin_idx': prefix_pin_idx,
        }
    else:
        return None


def object_ref(pb_name, pin_name, pin_idx=None):
    pin_addr = ''
    if pin_idx is not None:
        pin_addr = '[{}]'.format(pin_idx)

    return '{}.{}{}'.format(pb_name, pin_name, pin_addr)


def main():
    mydir = os.path.dirname(__file__)
    prjxray_db = os.path.abspath(
        os.path.join(mydir, "..", "..", "third_party", "prjxray-db")
    )

    db_types = prjxray.db.get_available_databases(prjxray_db)

    parser = argparse.ArgumentParser(
        description=__doc__, fromfile_prefix_chars='@', prefix_chars='-~'
    )

    parser.add_argument(
        '--part',
        choices=[os.path.basename(db_type) for db_type in db_types],
        help="""Project X-Ray database to use."""
    )

    parser.add_argument('--tile', help="""Tile to generate for""")

    parser.add_argument(
        '--site_directory', help="""Diretory where sites are defined"""
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
        '--output-tile',
        nargs='?',
        type=argparse.FileType('w'),
        default=sys.stdout,
        help="""File to write the output too."""
    )

    parser.add_argument(
        '--pin_assignments', required=True, type=argparse.FileType('r')
    )

    parser.add_argument(
        '--site_types',
        required=True,
        help="Comma seperated list of site types to include in this tile."
    )

    parser.add_argument(
        '--fused_sites',
        action='store_true',
        help=
        "Typically a tile can treat the sites within the tile as independent.  For tiles where this is not true, fused sites only imports 1 primatative for the entire tile, which should be named the same as the tile type."
    )

    args = parser.parse_args()

    db = prjxray.db.Database(os.path.join(prjxray_db, args.part))

    tile = db.get_tile_type(args.tile)

    # Wires sink to a site within the tile are input wires.
    input_wires = set()

    # Wires source from a site within the tile are output wires.
    output_wires = set()

    if not args.fused_sites:
        site_type_instances = {}
        for s in args.site_types.split(','):
            site_type, site_type_instance = s.split('/')

            if site_type not in site_type_instances:
                site_type_instances[site_type] = []

            site_type_instances[site_type].append(site_type_instance)

        imported_site_types = set()
        ignored_site_types = set()

        for site in tile.get_sites():
            site_type = db.get_site_type(site.type)

            if site.type not in site_type_instances:
                ignored_site_types.add(site.type)
                continue

            imported_site_types.add(site.type)

            for site_pin in site.site_pins:
                site_type_pin = site_type.get_site_pin(site_pin.name)

                if site_type_pin.direction == prjxray.site_type.SitePinDirection.IN:
                    if site_pin.wire is not None:
                        input_wires.add(site_pin.wire)
                elif site_type_pin.direction == prjxray.site_type.SitePinDirection.OUT:
                    if site_pin.wire is not None:
                        output_wires.add(site_pin.wire)
                else:
                    assert False, site_type_pin.direction

        # Make sure all requested site types actually get imported.
        assert len(set(site_type_instances.keys()) - imported_site_types
                   ) == 0, (site_type_instances.keys(), imported_site_types)

        for ignored_site_type in ignored_site_types:
            print(
                '*** WARNING *** Ignored site type {} in tile type {}'.format(
                    ignored_site_type, args.tile
                ),
                file=sys.stderr
            )
    else:
        for site in tile.get_sites():
            site_type = db.get_site_type(site.type)

            for site_pin in site.site_pins:
                site_type_pin = site_type.get_site_pin(site_pin.name)

                if site_type_pin.direction == prjxray.site_type.SitePinDirection.IN:
                    if site_pin.wire is not None:
                        input_wires.add(site_pin.wire)
                elif site_type_pin.direction == prjxray.site_type.SitePinDirection.OUT:
                    if site_pin.wire is not None:
                        output_wires.add(site_pin.wire)
                else:
                    assert False, site_type_pin.direction

    site_model = args.site_directory + "/{0}/{1}.model.xml"
    site_pbtype = args.site_directory + "/{0}/{1}.pb_type.xml"

    xi_url = "http://www.w3.org/2001/XInclude"
    ET.register_namespace('xi', xi_url)
    xi_include = "{%s}include" % xi_url

    ##########################################################################
    # Generate the model.xml file                                            #
    ##########################################################################

    model_xml = ET.Element(
        'models',
        nsmap={'xi': xi_url},
    )

    def add_model_include(site_type, instance_name):
        ET.SubElement(
            model_xml, xi_include, {
                'href':
                    site_model.format(
                        site_type.lower(), instance_name.lower()
                    ),
                'xpointer':
                    "xpointer(models/child::node())"
            }
        )

    if not args.fused_sites:
        site_types = set(site.type for site in tile.get_sites())
        for site_type in site_types:
            if site_type in ignored_site_types:
                continue

            for instance in site_type_instances[site_type]:
                add_model_include(site_type, instance)
    else:
        fused_site_name = args.tile.lower()

        add_model_include(fused_site_name, fused_site_name)

    model_str = ET.tostring(model_xml, pretty_print=True).decode('utf-8')
    args.output_model.write(model_str)
    args.output_model.close()

    ##########################################################################
    # Generate the pb_type.xml file                                          #
    ##########################################################################

    def add_direct(xml, input, output):
        ET.SubElement(
            xml, 'direct', {
                'name': '{}_to_{}'.format(input, output),
                'input': input,
                'output': output
            }
        )

    def add_pinlocations(xml, fc_xml, pin_assignments, tile):
        pinlocations_xml = ET.SubElement(
            xml, 'pinlocations', {
                'pattern': 'custom',
            }
        )

        if len(input_wires) > 0 or len(output_wires) > 0:
            sides = {}
            for pin in input_wires | output_wires:
                for side in pin_assignments['pin_directions'][tile][pin]:
                    if side not in sides:
                        sides[side] = []

                    sides[side].append(object_ref(tile_name, pin))

            for side, pins in sides.items():
                ET.SubElement(
                    pinlocations_xml, 'loc', {
                        'side': side.lower(),
                    }
                ).text = ' '.join(pins)

        direct_pins = set()
        for direct in pin_assignments['direct_connections']:
            if direct['from_pin'].split('.')[0] == tile:
                direct_pins.add(direct['from_pin'].split('.')[1])

            if direct['to_pin'].split('.')[0] == tile:
                direct_pins.add(direct['to_pin'].split('.')[1])

        for fc_override in direct_pins:
            ET.SubElement(
                fc_xml, 'fc_override', {
                    'fc_type': 'frac',
                    'fc_val': '0.0',
                    'port_name': fc_override,
                }
            )

    def add_switchblock_locations(xml):
        ET.SubElement(xml, 'switchblock_locations', {
            'pattern': 'all',
        })

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

    tile_name = args.tile

    pb_type_xml = ET.Element(
        'pb_type',
        {
            'name': tile_name,
        },
        nsmap={'xi': xi_url},
    )

    # Adding Fc to pb_type
    fc_xml = add_fc(pb_type_xml)

    interconnect_xml = ET.Element('interconnect')

    pb_type_xml.append(ET.Comment(" Tile Inputs "))

    # Input definitions for the TILE
    for name in sorted(input_wires):
        input_type = 'input'

        if 'CLK' in name:
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

    pb_type_xml.append(ET.Comment(" Internal Sites "))

    cell_names = {}

    if not args.fused_sites:
        site_type_count = {}
        site_prefixes = {}
        cells_idx = []

        site_type_ports = {}
        for idx, site in enumerate(tile.get_sites()):
            if site.type in ignored_site_types:
                continue

            if site.type not in site_type_count:
                site_type_count[site.type] = 0
                site_prefixes[site.type] = []

            cells_idx.append(site_type_count[site.type])
            site_type_count[site.type] += 1
            site_prefix = '{}_X{}'.format(site.type, site.x)

            site_instance = site_type_instances[site.type][cells_idx[idx]]

            print(site_prefix, site_instance)

            site_type_path = site_pbtype.format(
                site.type.lower(), site_instance.lower()
            )
            cell_pb_type = ET.ElementTree()
            root_element = cell_pb_type.parse(site_type_path)
            cell_names[site_instance] = root_element.attrib['name']

            ports = {}
            for inputs in root_element.iter('input'):
                ports[inputs.attrib['name']] = int(inputs.attrib['num_pins'])

            for clocks in root_element.iter('clock'):
                ports[clocks.attrib['name']] = int(clocks.attrib['num_pins'])

            for outputs in root_element.iter('output'):
                ports[outputs.attrib['name']] = int(outputs.attrib['num_pins'])

            assert site_instance not in site_type_ports, (
                site_instance, site_type_ports.keys()
            )
            site_type_ports[site_instance] = ports

            attrib = dict(root_element.attrib)
            include_xml = ET.SubElement(pb_type_xml, 'pb_type', attrib)
            ET.SubElement(
                include_xml, xi_include, {
                    'href':
                        site_type_path,
                    'xpointer':
                        "xpointer(pb_type/child::node()[local-name()!='metadata'])",
                }
            )

            metadata_xml = ET.SubElement(include_xml, 'metadata')
            ET.SubElement(
                metadata_xml, 'meta', {
                    'name': 'fasm_prefix',
                }
            ).text = site_prefix

            # Import pb_type metadata if it exists.
            if any(child.tag == 'metadata' for child in root_element):
                ET.SubElement(
                    metadata_xml, xi_include, {
                        'href': site_type_path,
                        'xpointer': "xpointer(pb_type/metadata/child::node())",
                    }
                )

        for idx, site in enumerate(tile.get_sites()):
            if site.type in ignored_site_types:
                continue

            site_idx = cells_idx[idx]
            site_instance = site_type_instances[site.type][site_idx]
            site_name = cell_names[site_instance]

            site_type = db.get_site_type(site.type)

            interconnect_xml.append(ET.Comment(" Tile->Site "))
            for site_pin in sorted(site.site_pins,
                                   key=lambda site_pin: site_pin.name):
                if site_pin.wire is None:
                    continue

                port = find_port(site_pin.name, site_type_ports[site_instance])
                if port is None:
                    print(
                        "*** WARNING *** Didn't find port for name {} for site type {}"
                        .format(site_pin.name, site.type),
                        file=sys.stderr
                    )
                    continue

                site_type_pin = site_type.get_site_pin(site_pin.name)

                if site_type_pin.direction == prjxray.site_type.SitePinDirection.IN:
                    add_direct(
                        interconnect_xml,
                        input=object_ref(tile_name, site_pin.wire),
                        output=object_ref(site_name, **port)
                    )
                elif site_type_pin.direction == prjxray.site_type.SitePinDirection.OUT:
                    pass
                else:
                    assert False, site_type_pin.direction

            interconnect_xml.append(ET.Comment(" Site->Tile "))
            for site_pin in sorted(site.site_pins,
                                   key=lambda site_pin: site_pin.name):
                if site_pin.wire is None:
                    continue

                port = find_port(site_pin.name, site_type_ports[site_instance])
                if port is None:
                    continue

                site_type_pin = site_type.get_site_pin(site_pin.name)

                if site_type_pin.direction == prjxray.site_type.SitePinDirection.IN:
                    pass
                elif site_type_pin.direction == prjxray.site_type.SitePinDirection.OUT:
                    add_direct(
                        interconnect_xml,
                        input=object_ref(site_name, **port),
                        output=object_ref(tile_name, site_pin.wire),
                    )
                else:
                    assert False, site_type_pin.direction
    else:
        site_type_ports = {}

        site_type_path = site_pbtype.format(fused_site_name, fused_site_name)
        cell_pb_type = ET.ElementTree()
        root_element = cell_pb_type.parse(site_type_path)

        ports = {}
        for inputs in root_element.iter('input'):
            ports[inputs.attrib['name']] = int(inputs.attrib['num_pins'])

        for clocks in root_element.iter('clock'):
            ports[clocks.attrib['name']] = int(clocks.attrib['num_pins'])

        for outputs in root_element.iter('output'):
            ports[outputs.attrib['name']] = int(outputs.attrib['num_pins'])

        attrib = dict(root_element.attrib)
        include_xml = ET.SubElement(pb_type_xml, 'pb_type', attrib)
        ET.SubElement(
            include_xml, xi_include, {
                'href': site_type_path,
                'xpointer': "xpointer(pb_type/child::node())",
            }
        )

        site_name = root_element.attrib['name']

        def fused_port_name(site, site_pin):
            return '{}_{}_{}'.format(site.prefix, site.name, site_pin.name)

        for idx, site in enumerate(tile.get_sites()):
            site_type = db.get_site_type(site.type)

            interconnect_xml.append(ET.Comment(" Tile->Site "))
            for site_pin in sorted(site.site_pins,
                                   key=lambda site_pin: site_pin.name):
                if site_pin.wire is None:
                    continue

                port_name = fused_port_name(site, site_pin)
                port = find_port(port_name, ports)
                if port is None:
                    print(
                        "*** WARNING *** Didn't find port for name {} for site type {}"
                        .format(port_name, site.type),
                        file=sys.stderr
                    )
                    continue

                site_type_pin = site_type.get_site_pin(site_pin.name)

                if site_type_pin.direction == prjxray.site_type.SitePinDirection.IN:
                    add_direct(
                        interconnect_xml,
                        input=object_ref(tile_name, site_pin.wire),
                        output=object_ref(site_name, **port)
                    )
                elif site_type_pin.direction == prjxray.site_type.SitePinDirection.OUT:
                    pass
                else:
                    assert False, site_type_pin.direction

            interconnect_xml.append(ET.Comment(" Site->Tile "))
            for site_pin in sorted(site.site_pins,
                                   key=lambda site_pin: site_pin.name):
                if site_pin.wire is None:
                    continue

                port = find_port(fused_port_name(site, site_pin), ports)
                if port is None:
                    # Already warned above
                    continue

                site_type_pin = site_type.get_site_pin(site_pin.name)

                if site_type_pin.direction == prjxray.site_type.SitePinDirection.IN:
                    pass
                elif site_type_pin.direction == prjxray.site_type.SitePinDirection.OUT:
                    add_direct(
                        interconnect_xml,
                        input=object_ref(site_name, **port),
                        output=object_ref(tile_name, site_pin.wire),
                    )
                else:
                    assert False, site_type_pin.direction

    pb_type_xml.append(interconnect_xml)

    pin_assignments = json.load(args.pin_assignments)

    add_pinlocations(pb_type_xml, fc_xml, pin_assignments, args.tile)

    add_switchblock_locations(pb_type_xml)

    pb_type_str = ET.tostring(pb_type_xml, pretty_print=True).decode('utf-8')
    args.output_pb_type.write(pb_type_str)
    args.output_pb_type.close()

    ##########################################################################
    # Generate the tile.xml file                                             #
    ##########################################################################

    tile_xml = ET.Element(
        'tile',
        {
            'name': tile_name,
        },
        nsmap={'xi': xi_url},
    )

    fc_xml = add_fc(tile_xml)

    add_pinlocations(tile_xml, fc_xml, pin_assignments, args.tile)

    add_switchblock_locations(tile_xml)

    tile_str = ET.tostring(tile_xml, pretty_print=True).decode('utf-8')
    args.output_tile.write(tile_str)
    args.output_tile.close()


if __name__ == '__main__':
    main()
