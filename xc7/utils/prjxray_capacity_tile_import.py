#!/usr/bin/env python3
"""
Creates the tile, pb_type and model xmls needed for tiles having
a capacity > 1.

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
import sqlite3

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


def remove_vpr_tile_prefix(name):
    """ Removes tile prefix.

    Raises
    ------
    Assert error if name does not start with VPR_TILE_PREFIX
    """
    assert name.startswith(VPR_TILE_PREFIX)
    return name[len(VPR_TILE_PREFIX):]


def object_ref(pb_name, pin_name, pin_idx=None):
    pin_addr = ''
    if pin_idx is not None:
        pin_addr = '[{}]'.format(pin_idx)

    return '{}.{}{}'.format(pb_name, pin_name, pin_addr)


def add_direct(xml, input, output):
    """ Add a direct tag to the interconnect_xml. """
    ET.SubElement(
        xml, 'direct', {
            'name': '{}_to_{}'.format(input, output),
            'input': input,
            'output': output
        }
    )


def write_xml(location, xml):
    """ Writes XML to disk. """
    pb_type_str = ET.tostring(xml, pretty_print=True).decode('utf-8')
    with open(location, "w") as f:
        f.write(pb_type_str)
        f.close()


class ModelXml(object):
    """ Simple model.xml writter. """

    def __init__(self, f, site_directory):
        self.f = f
        self.model_xml = ET.Element(
            'models',
            nsmap={'xi': XI_URL},
        )
        self.site_model = site_directory + "/{0}/{1}.model.xml"

    def add_model_include(self, site_type, instance_name):
        ET.SubElement(
            self.model_xml, XI_INCLUDE, {
                'href':
                    self.site_model.format(
                        site_type.lower(), instance_name.lower()
                    ),
                'xpointer':
                    "xpointer(models/child::node())"
            }
        )

    def write_model(self):
        write_xml(self.f, self.model_xml)


def reduce_pin_directions(pin_directions):

    reduced_pin_directions = dict()
    pins = pin_directions.keys()
    for pin in pins:
        reduced_pin = pin.split('_')[-1]
        if reduced_pin not in reduced_pin_directions.keys():
            reduced_pin_directions[reduced_pin] = pin_directions[pin]

    return reduced_pin_directions


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

    tile_name = remove_vpr_tile_prefix(tile_name)

    reduced_pin_directions = reduce_pin_directions(pin_assignments['pin_directions'][tile_name])

    sides = {}
    for pin in wires:
        for side in reduced_pin_directions[pin]:
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


def start_tile(tile_name, f_pin_assignments, input_wires, output_wires, capacity, eq_sites):
    """ Starts a tile by adding input, clock and output tags. """

    tile_name = add_vpr_tile_prefix(tile_name)

    tile_xml = ET.Element(
        'tile',
        {
            'name': tile_name,
            'capacity': capacity,
        }
    )

    tile_xml.append(ET.Comment(" Tile Inputs "))

    # Input definitions for the TILE
    for name in sorted(input_wires):
        input_type = 'input'

        if 'CLK' in name:
            input_type = 'clock'

        ET.SubElement(
            tile_xml,
            input_type,
            {
                'name': name,
                'num_pins': '1'
            },
        )

    tile_xml.append(ET.Comment(" Tile Outputs "))
    for name in sorted(output_wires):
        # Output definitions for the TILE
        ET.SubElement(
            tile_xml,
            'output',
            {
                'name': name,
                'num_pins': '1'
            },
        )

    fc_xml = add_fc(tile_xml)

    pin_assignments = json.load(f_pin_assignments)
    add_pinlocations(
        tile_name, tile_xml, fc_xml, pin_assignments,
        input_wires | output_wires
    )

    equivalent_sites_xml = ET.SubElement(tile_xml, 'equivalent_sites')

    for eq_site in eq_sites:
        site_xml = ET.SubElement(
            equivalent_sites_xml, 'site', {
                'pb_type': add_vpr_tile_prefix(eq_site),
            }
        )

    tile_xml.append(ET.Comment(" Internal Sites "))

    return tile_xml


def start_pb_type(pb_type_name, input_wires, output_wires):
    """ Starts a pb_type by adding input, clock and output tags. """

    pb_type_xml = ET.Element(
        'pb_type', { 'name': add_vpr_tile_prefix(pb_type_name), },
        nsmap={'xi': XI_URL},
    )

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

    return pb_type_xml


def import_capacity_tile(db, args):
    """ Create a root-level pb_type with the reduced set of pins.
    """

    site = args.site_type

    site_type = db.get_site_type(site)

    # Wires sink to a site within the tile are input wires.
    input_wires = set()

    # Wires source from a site within the tile are output wires.
    output_wires = set()

    for site_pin in site_type.get_site_pins():
        site_type_pin = site_type.get_site_pin(site_pin)

        if site_type_pin.direction == prjxray.site_type.SitePinDirection.IN:
            input_wires.add(site_type_pin.name)
        elif site_type_pin.direction == prjxray.site_type.SitePinDirection.OUT:
            output_wires.add(site_type_pin.name)
        else:
            assert False, site_type_pin.direction

    ##########################################################################
    # Generate the model.xml file                                            #
    ##########################################################################

    model = ModelXml(f=os.path.join(args.output_directory, args.tile.lower(), '{}.model.xml'.format(args.tile.lower())), site_directory=args.site_directory)
    model.add_model_include(site, site)
    model.write_model()

    ##########################################################################
    # Generate the tile.xml file                                             #
    ##########################################################################

    tile_name = args.tile
    equivalent_sites = args.equivalent_sites.split(',')
    tile_xml = start_tile(
        tile_name, args.pin_assignments, input_wires, output_wires, args.capacity, equivalent_sites
    )
    write_xml(os.path.join(args.output_directory, args.tile.lower(), '{}.tile.xml'.format(args.tile.lower())), tile_xml)

    ##########################################################################
    # Generate the pb_type.xml file                                          #
    ##########################################################################

    pb_type_name = args.pb_type
    pb_type_xml = start_pb_type(
        pb_type_name, input_wires, output_wires
    )

    site_pbtype = args.site_directory + "/{0}/{1}.pb_type.xml"
    site_type_path = site_pbtype.format(site.lower(), site.lower())
    ET.SubElement(pb_type_xml, XI_INCLUDE, {
        'href': site_type_path,
    })

    cell_pb_type = ET.ElementTree()
    root_element = cell_pb_type.parse(site_type_path)
    site_name = root_element.attrib['name']

    interconnect_xml = ET.Element('interconnect')

    interconnect_xml.append(ET.Comment(" Tile->Site "))
    for site_pin in sorted(site_type.get_site_pins()):
        site_type_pin = site_type.get_site_pin(site_pin)
        if site_type_pin.direction == prjxray.site_type.SitePinDirection.IN:
            add_direct(
                interconnect_xml,
                input=object_ref(add_vpr_tile_prefix(pb_type_name), site_pin),
                output=object_ref(site_name, site_pin)
            )
        elif site_type_pin.direction == prjxray.site_type.SitePinDirection.OUT:
            pass
        else:
            assert False, site_type_pin.direction

    interconnect_xml.append(ET.Comment(" Site->Tile "))
    for site_pin in sorted(site_type.get_site_pins()):
        site_type_pin = site_type.get_site_pin(site_pin)
        if site_type_pin.direction == prjxray.site_type.SitePinDirection.IN:
            pass
        elif site_type_pin.direction == prjxray.site_type.SitePinDirection.OUT:
            add_direct(
                interconnect_xml,
                input=object_ref(site_name, site_pin),
                output=object_ref(add_vpr_tile_prefix(pb_type_name), site_pin),
            )
        else:
            assert False, site_type_pin.direction

    pb_type_xml.append(interconnect_xml)

    write_xml(os.path.join(args.output_directory, args.tile.lower(), '{}.pb_type.xml'.format(args.tile.lower())), pb_type_xml)


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
        required=True,
        choices=[os.path.basename(db_type) for db_type in db_types],
        help="""Project X-Ray database to use."""
    )

    parser.add_argument('--tile', required=True, help="""Tile to generate for""")

    parser.add_argument('--pb_type', required=True, help="""pb_type to generate for""")

    parser.add_argument(
        '--site_directory', required=True, help="""Diretory where sites are defined"""
    )

    parser.add_argument(
        '--output_directory',
        required=True,
        help="Directory to write output XML too.",
    )

    parser.add_argument(
        '--pin_assignments', required=True, type=argparse.FileType('r')
    )

    parser.add_argument(
        '--site_type',
        required=True,
        help="Site type to include in this tile."
    )

    parser.add_argument(
        '--capacity', required=True, help="Required capacity for the tile."
    )

    parser.add_argument(
        '--equivalent_sites', help="Equivalent sites that can be placed within this tile."
    )

    args = parser.parse_args()

    db = prjxray.db.Database(os.path.join(prjxray_db, args.part))

    ET.register_namespace('xi', XI_URL)

    import_capacity_tile(db, args)


if __name__ == '__main__':
    main()
