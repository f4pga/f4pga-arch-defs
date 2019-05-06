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

XI_URL = "http://www.w3.org/2001/XInclude"

# Macros used to select relevant port names
PORT_TAGS = ['input', 'output', 'clock']


def prefix_name(tile):
    """ Add tile prefix.

    This avoids namespace collision when embedding a site (e.g. SLICEL) as a
    tile.
    """
    return 'BLK-TL-' + tile


def object_ref(pb_name, pin_name, pin_idx=None):
    pin_addr = ''
    if pin_idx is not None:
        pin_addr = '[{}]'.format(pin_idx)

    return '{}.{}{}'.format(pb_name, pin_name, pin_addr)


def import_physical_tile(args):
    """ Imports the physical tile.

    This created the actual tile.xml definition of the tile which will be
    merged in the arch.xml.
    """

    ##########################################################################
    # Utility functions to create tile tag.                                  #
    ##########################################################################

    def get_ports_from_xml(xml):
        """ Used to retrieve ports from a given XML root of a pb_type."""
        ports = set()

        for child in xml:
            if child.tag in PORT_TAGS:
                ports.add(child.attrib['name'])

        return ports

    def add_pinlocations(xml, fc_xml, pin_assignments, tile):
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
        for port in ports:
            for side in pin_assignments['pin_directions'][tile][port]:
                if side not in sides:
                    sides[side] = []

                sides[side].append(object_ref(prefix_name(tile_name), port))

        for side, pins in sides.items():
            ET.SubElement(pinlocations_xml, 'loc', {
                'side': side.lower(),
            }).text = ' '.join(pins)

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

    def add_equivalent_tiles(xml, equivalent_tiles):
        """ Used to add to the <tile> tag the equivalent tiles associated with it."""

        if not equivalent_tiles:
            return

        equivalent_tiles_xml = ET.SubElement(xml, 'equivalent_tiles')

        for eq_tile in equivalent_tiles.split(','):
            eq_pb_type_xml = ET.parse(
                "{}/{tile}/{tile}.pb_type.xml".format(
                    args.tiles_directory, tile=eq_tile.lower()
                )
            )
            root = eq_pb_type_xml.getroot()

            mode_xml = ET.SubElement(
                equivalent_tiles_xml, 'mode', {'name': prefix_name(eq_tile)}
            )

            for port in ports:
                port_xml = ET.SubElement(
                    mode_xml, 'map', {
                        'from': port,
                        'to': port
                    }
                )

    ##########################################################################
    # Generate the tile.xml file                                             #
    ##########################################################################

    tile_name = args.tile

    pb_type_xml = ET.parse(
        "{}/{tile}/{tile}.pb_type.xml".format(
            args.tiles_directory, tile=tile_name.lower()
        )
    )
    pb_type_root = pb_type_xml.getroot()

    ports = sorted(get_ports_from_xml(pb_type_root))

    tile_xml = ET.Element(
        'tile',
        {
            'name': prefix_name(tile_name),
        },
        nsmap={'xi': XI_URL},
    )

    equivalent_tiles = args.equivalent_tiles
    add_equivalent_tiles(tile_xml, equivalent_tiles)

    fc_xml = add_fc(tile_xml)

    pin_assignments = json.load(args.pin_assignments)
    add_pinlocations(tile_xml, fc_xml, pin_assignments, tile_name)

    add_switchblock_locations(tile_xml)

    tile_str = ET.tostring(tile_xml, pretty_print=True).decode('utf-8')
    args.output_tile.write(tile_str)
    args.output_tile.close()


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

    ET.register_namespace('xi', XI_URL)

    import_physical_tile(args)


if __name__ == '__main__':
    main()
