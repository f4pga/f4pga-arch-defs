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

import lxml.etree as ET

def main():
    mydir = os.path.dirname(__file__)
    prjxray_db = os.path.abspath(os.path.join(mydir, "..", "..", "third_party", "prjxray-db"))

    db_types = prjxray.db.get_available_databases(prjxray_db)

    parser = argparse.ArgumentParser(
        description=__doc__,
        fromfile_prefix_chars='@',
        prefix_chars='-~'
    )

    parser.add_argument(
        '--part', choices=[os.path.basename(db_type) for db_type in db_types],
        help="""Project X-Ray database to use.""")

    parser.add_argument(
        '--tile',
        help="""Tile to generate for""")

    parser.add_argument(
        '--site_directory',
        help="""Diretory where sites are defined""")

    parser.add_argument(
        '--output-pb-type', nargs='?', type=argparse.FileType('w'), default=sys.stdout,
        help="""File to write the output too.""")

    parser.add_argument(
        '--output-model', nargs='?', type=argparse.FileType('w'), default=sys.stdout,
        help="""File to write the output too.""")

    parser.add_argument(
            '--pin_assignments', required=True, type=argparse.FileType('r'))

    parser.add_argument(
            '--site_types', required=True, help="Comma seperated list of site types to include in this tile.")

    args = parser.parse_args()

    db = prjxray.db.Database(os.path.join(prjxray_db, args.part))

    tile = db.get_tile_type(args.tile)

    # Wires sink to a site within the tile are input wires.
    input_wires = set()

    # Wires source from a site within the tile are output wires.
    output_wires = set()

    site_types_to_import = set(args.site_types.split(','))
    imported_site_types = set()
    ignored_site_types = set()

    for site in tile.get_sites():
        site_type = db.get_site_type(site.type)

        if site.type not in site_types_to_import:
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
    assert len(site_types_to_import - imported_site_types) == 0, (
            site_types_to_import, imported_site_types)

    for ignored_site_type in ignored_site_types:
        print('*** WARNING *** Ignored site type {} in tile type {}'.format(
            ignored_site_type, args.tile), file=sys.stderr)

    site_model = args.site_directory + "/{0}/{0}.model.xml"
    site_pbtype = args.site_directory + "/{0}/{0}.pb_type.xml"

    xi_url = "http://www.w3.org/2001/XInclude"
    ET.register_namespace('xi', xi_url)
    xi_include = "{%s}include" % xi_url

    ##########################################################################
    # Generate the model.xml file                                            #
    ##########################################################################


    model_xml = ET.Element(
        'models', nsmap = {'xi': xi_url},
    )

    def add_model_include(name):
        ET.SubElement(model_xml, xi_include, {
            'href': site_model.format(name.lower()),
            'xpointer': "xpointer(models/child::node())"})

    site_types = set(site.type for site in tile.get_sites())
    for site_type in site_types:
        add_model_include(site_type)

    model_str = ET.tostring(model_xml, pretty_print=True).decode('utf-8')
    args.output_model.write(model_str)
    args.output_model.close()

    ##########################################################################
    # Generate the pb_type.xml file                                          #
    ##########################################################################

    def add_direct(xml, input, output):
        ET.SubElement(xml, 'direct', {
                'name': '{}_to_{}'.format(input, output),
                'input': input,
                'output': output})

    tile_name = "BLK_TI-{}".format(args.tile)

    pb_type_xml = ET.Element(
        'pb_type', {
            'name': tile_name,
        },
        nsmap = {'xi': xi_url},
    )

    fc_xml = ET.SubElement(pb_type_xml, 'fc', {
            'in_type':'abs',
            'in_val':'2',
            'out_type': 'abs',
            'out_val':'2',
    })

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
            {'name': name, 'num_pins': '1'},
        )

    pb_type_xml.append(ET.Comment(" Tile Outputs "))
    for name in sorted(output_wires):
        # Output definitions for the TILE
        ET.SubElement(
            pb_type_xml,
            'output',
            {'name': name, 'num_pins': '1'},
        )

    pb_type_xml.append(ET.Comment(" Internal Sites "))

    def object_ref(pb_name, pin_name, pb_idx=None):
        if pb_idx is None:
            return '{}.{}'.format(pb_name, pin_name)
        else:
            return '{}[{}].{}'.format(pb_name, pb_idx, pin_name)

    cell_names = {}

    site_type_count = {}
    site_prefixes = {}
    cells_idx = []
    for idx, site in enumerate(tile.get_sites()):
        if site.type not in site_type_count:
            site_type_count[site.type] = 0
            site_prefixes[site.type] = []

        cells_idx.append(site_type_count[site.type])
        site_type_count[site.type] += 1
        site_prefixes[site.type].append('{}_X{}'.format(site.type, site.x))

    for site_type in sorted(site_type_count):
        site_type_path = site_pbtype.format(site.type.lower())
        cell_pb_type = ET.ElementTree()
        root_element = cell_pb_type.parse(site_type_path)
        cell_names[site_type] = root_element.attrib['name']

        attrib = dict(root_element.attrib)
        attrib['num_pb'] = str(site_type_count[site_type])
        include_xml = ET.SubElement(pb_type_xml, 'pb_type', attrib)
        ET.SubElement(include_xml, xi_include, {
            'href': site_type_path,
            'xpointer':
            "xpointer(pb_type/child::node()[local-name()!='metadata'])",
            })

        metadata_xml = ET.SubElement(include_xml, 'metadata')
        ET.SubElement(metadata_xml, 'meta', {
                'name': 'fasm_prefix',
        }).text = ' '.join(site_prefixes[site_type])

        # Import pb_type metadata if it exists.
        if len(tuple(root_element.iter('metadata'))) > 0:
            ET.SubElement(metadata_xml, xi_include, {
                'href': site_type_path,
                'xpointer': "xpointer(pb_type/metadata/child::node())",
                })

    for idx, site in enumerate(tile.get_sites()):
        site_name = cell_names[site.type]
        site_idx = cells_idx[idx]

        site_type = db.get_site_type(site.type)

        interconnect_xml.append(ET.Comment(" Tile->Site "))
        for site_pin in sorted(site.site_pins, key=lambda site_pin: site_pin.name):
            if site_pin.wire is None:
                continue

            site_type_pin = site_type.get_site_pin(site_pin.name)

            if site_type_pin.direction == prjxray.site_type.SitePinDirection.IN:
                add_direct(interconnect_xml,
                        input=object_ref(tile_name, site_pin.wire),
                        output=object_ref(site_name, site_pin.name, pb_idx=site_idx)
                           )
            elif site_type_pin.direction == prjxray.site_type.SitePinDirection.OUT:
                pass
            else:
                assert False, site_type_pin.direction

        interconnect_xml.append(ET.Comment(" Site->Tile "))
        for site_pin in sorted(site.site_pins, key=lambda site_pin: site_pin.name):
            if site_pin.wire is None:
                continue

            site_type_pin = site_type.get_site_pin(site_pin.name)

            if site_type_pin.direction == prjxray.site_type.SitePinDirection.IN:
                pass
            elif site_type_pin.direction == prjxray.site_type.SitePinDirection.OUT:
                add_direct(interconnect_xml,
                        input=object_ref(site_name, site_pin.name, pb_idx=site_idx),
                        output=object_ref(tile_name, site_pin.wire),
                        )
            else:
                assert False, site_type_pin.direction


    pb_type_xml.append(interconnect_xml)

    ET.SubElement(pb_type_xml, 'switchblock_locations', {
            'pattern': 'all',
    })

    pinlocations_xml = ET.SubElement(pb_type_xml, 'pinlocations', {
            'pattern': 'custom',
    })

    if len(input_wires) > 0 or len(output_wires) > 0:
        pin_assignments = json.load(args.pin_assignments)

        sides = {}
        for pin in input_wires | output_wires:
            for side in pin_assignments['pin_directions'][args.tile][pin]:
                if side not in sides:
                    sides[side] = []

                sides[side].append(object_ref(tile_name, pin))


        for side, pins in sides.items():
            ET.SubElement(pinlocations_xml, 'loc', {
                    'side': side.lower(),
            }).text = ' '.join(pins)

    metadata_xml = ET.SubElement(pb_type_xml, 'metadata')
    ET.SubElement(metadata_xml, 'meta', {
            'name': 'fasm_prefix',
    }).text = args.tile

    direct_pins = set()
    for direct in pin_assignments['direct_connections']:
        if direct['from_pin'].split('.')[0] == args.tile:
            direct_pins.add(direct['from_pin'].split('.')[1])

        if direct['to_pin'].split('.')[0] == args.tile:
            direct_pins.add(direct['to_pin'].split('.')[1])

    for fc_override in direct_pins:
        ET.SubElement(fc_xml, 'fc_override', {
            'fc_type': 'frac',
            'fc_val': '0.0',
            'port_name': fc_override,
            })

    pb_type_str = ET.tostring(pb_type_xml, pretty_print=True).decode('utf-8')
    args.output_pb_type.write(pb_type_str)
    args.output_pb_type.close()

if __name__ == '__main__':
    main()
