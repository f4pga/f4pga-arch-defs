#!/usr/bin/env python3
"""
Import the top level tile information from Project X-Ray database
files.

Project X-Ray specifies the connections between tiles and the connect
between tiles and their sites.  prjxray_tile_type_import generates a VPR tile
that has the correct tile pin location, switchblock location and fc information.

Optionally, if there are available equivalent tiles, the tile information is filled
with the equivalent tile pin mapping as well. This is needed by VPR to have a correct
translation of the pin names when using the equivalent tile.

"""

from __future__ import print_function
import argparse
import os
import sys
import prjxray.db
import os.path
import simplejson as json

import lxml.etree as ET


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
        '--tiles-directory', help="""Diretory where tiles are defined"""
    )

    parser.add_argument(
        '--equivalent-tiles',
        help="""Comma separated list of equivalent tiles.""",
    )

    parser.add_argument(
        '--pin-prefix',
        help=
        """Comma separated list of prefix translation pairs for equivalent tiles.""",
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

    args = parser.parse_args()

    tile_name = args.tile

    xi_url = "http://www.w3.org/2001/XInclude"
    ET.register_namespace('xi', xi_url)

    # Macros used to select relevant port names
    IN_PORT_TAG = ['input', 'clock']
    OUT_PORT_TAG = ['output']

    ##########################################################################
    # Utility functions to create tile tag.                                  #
    ##########################################################################

    def get_port_name(port):
        """Used to split the port in port full name, port name and pin name"""
        split = port.split('_')
        pin = split[-1]
        port_name = "_".join(split[:-1])

        return (port, port_name, pin)

    def get_ports_from_xml(xml):
        """Used to retrieve ports from a given XML root of a pb_type."""
        input_wires = set()
        output_wires = set()
        for child in xml:
            if child.tag in IN_PORT_TAG:
                input_wires.add(get_port_name(child.attrib['name']))
            elif child.tag in OUT_PORT_TAG:
                output_wires.add(get_port_name(child.attrib['name']))

        return input_wires, output_wires

    def add_pinlocations(xml, fc_xml, pin_assignments, tile):
        pinlocations_xml = ET.SubElement(
            xml, 'pinlocations', {
                'pattern': 'custom',
            }
        )

        if len(input_wires) > 0 or len(output_wires) > 0:
            sides = {}
            for port, port_name, pin in input_wires | output_wires:
                for side in pin_assignments['pin_directions'][tile][port]:
                    if side not in sides:
                        sides[side] = []

                    sides[side].append(object_ref(tile_name, port))

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

    def get_equivalent_port(port_name, pin_name, pin_prefix, eq_ports):
        """ Used to get the full name of the equivalent port.
            input:
                - port_name: port name of the current tile
                - pin_name: pin name of the current tile
                - pin_prefix: dict containing the possible translations of the port name into the
                              equivalent port name
                - eq_ports: set of equivalent ports from which the function gets the equivalent full port name
        """
        for port, eq_port_name, pin in eq_ports:
            if pin == pin_name and eq_port_name in pin_prefix[port_name]:
                return port

        return None

    def add_equivalent_tiles(xml, equivalent_tiles, pin_prefix):
        """ Used to add to the <tile> tag the equivalent tiles associated with it."""

        if not equivalent_tiles:
            return

        equivalent_tiles_xml = ET.SubElement(xml, 'equivalent_tiles')

        pin_prefix_dict = dict()
        for prefix in pin_prefix.split(','):
            prefix = prefix.split('/')
            pin_prefix_dict[prefix[0]] = prefix[1]

        for eq_tile in equivalent_tiles.split(','):
            eq_pb_type_xml = ET.parse(
                "{}/{tile}/{tile}.pb_type.xml".format(
                    args.tiles_directory, tile=eq_tile.lower()
                )
            )
            root = eq_pb_type_xml.getroot()

            eq_input_wires, eq_output_wires = get_ports_from_xml(root)

            mode_xml = ET.SubElement(
                equivalent_tiles_xml, 'mode', {'name': eq_tile}
            )
            for port, port_name, pin in input_wires | output_wires:
                from_port = port
                to_port = get_equivalent_port(
                    port_name, pin, pin_prefix_dict,
                    eq_input_wires | eq_output_wires
                )
                assert to_port is not None, "Could not find the equivalent port."

                port_xml = ET.SubElement(
                    mode_xml, 'map', {
                        'from': from_port,
                        'to': to_port
                    }
                )

    ##########################################################################
    # Generate the tile.xml file                                             #
    ##########################################################################

    pb_type_xml = ET.parse(
        "{}/{tile}/{tile}.pb_type.xml".format(
            args.tiles_directory, tile=tile_name.lower()
        )
    )
    pb_type_root = pb_type_xml.getroot()

    input_wires, output_wires = get_ports_from_xml(pb_type_root)

    tile_xml = ET.Element(
        'tile',
        {
            'name': tile_name,
        },
        nsmap={'xi': xi_url},
    )

    pin_prefix = args.pin_prefix
    equivalent_tiles = args.equivalent_tiles
    add_equivalent_tiles(tile_xml, equivalent_tiles, pin_prefix)

    fc_xml = add_fc(tile_xml)

    pin_assignments = json.load(args.pin_assignments)
    add_pinlocations(tile_xml, fc_xml, pin_assignments, tile_name)

    add_switchblock_locations(tile_xml)

    tile_str = ET.tostring(tile_xml, pretty_print=True).decode('utf-8')
    args.output_tile.write(tile_str)
    args.output_tile.close()


if __name__ == '__main__':
    main()
