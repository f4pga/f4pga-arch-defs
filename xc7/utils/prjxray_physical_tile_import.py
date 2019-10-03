#!/usr/bin/env python3
"""
Import the physical tile information from Project X-Ray database
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
import copy
import prjxray.db
import os.path
import simplejson as json
import prjxray_tile_import as tile_import

import lxml.etree as ET

XI_URL = "http://www.w3.org/2001/XInclude"

# Macros used to select relevant port names
PORT_TAGS = ['input', 'output', 'clock']


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

    def add_ports(tile_xml, pb_type_xml):
        """ Used to copy the ports from a given XML root of a pb_type."""

        for child in pb_type_xml:
            if child.tag in PORT_TAGS:
                child_copy = copy.deepcopy(child)
                tile_xml.append(child_copy)

    def add_direct_mappings(tile_xml, site_xml, eq_pb_type_xml):
        """ Used to add the direct pin mappings between a pb_type and the corresponding tile """

        tile_ports = sorted(get_ports_from_xml(tile_xml))
        site_ports = sorted(get_ports_from_xml(eq_pb_type_xml))

        tile_name = tile_xml.attrib['name']
        site_name = site_xml.attrib['pb_type']

        for site_port in site_ports:
            for tile_port in tile_ports:
                if site_port == tile_port:
                    direct_map = ET.SubElement(
                        site_xml, 'direct',
                        {'from': "{}.{}".format(tile_name, tile_port),
                         'to': "{}.{}".format(site_name, site_port)})

    def add_equivalent_sites(tile_xml, equivalent_sites, inc_priority=False):
        """ Used to add to the <tile> tag the equivalent tiles associated with it."""

        pb_types = equivalent_sites.split(',')

        equivalent_sites_xml = ET.SubElement(tile_xml, 'equivalent_sites')

        priority = 0

        for eq_site in pb_types:
            eq_pb_type_xml = ET.parse(
                "{}/{tile}/{tile}.pb_type.xml".format(
                    args.tiles_directory, tile=eq_site.lower()
                )
            )
            pb_type_root = eq_pb_type_xml.getroot()

            site_xml = ET.SubElement(
                equivalent_sites_xml, 'site',
                {'pb_type': tile_import.add_vpr_tile_prefix(eq_site),
                 'priority': str(priority)}
            )

            if inc_priority:
                priority += 1

            add_direct_mappings(tile_xml, site_xml, pb_type_root)

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
            'name': tile_import.add_vpr_tile_prefix(tile_name),
        },
        nsmap={'xi': XI_URL},
    )

    add_ports(tile_xml, pb_type_root)

    equivalent_sites = args.equivalent_sites
    add_equivalent_sites(tile_xml, equivalent_sites, args.priority)

    fc_xml = tile_import.add_fc(tile_xml)

    pin_assignments = json.load(args.pin_assignments)
    tile_import.add_pinlocations(
        tile_name, tile_xml, fc_xml, pin_assignments, ports
    )

    tile_import.add_switchblock_locations(tile_xml)

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
        '--equivalent-sites',
        help=
        """Comma separated list of equivalent sites that can be placed in this tile.""",
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

    parser.add_argument('--priority', action='store_true')

    args = parser.parse_args()

    ET.register_namespace('xi', XI_URL)

    import_physical_tile(args)


if __name__ == '__main__':
    main()
