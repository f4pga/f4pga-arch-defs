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
from functools import reduce

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


def parse_site_type_instance(site_types):
    """ Convert site_types argument into map.

    Parameters
    ----------
    site_types : str

    Returns
    -------
    site_type_instances : map of str to list of str
        Maps site type to array of site type instances.  First instance of
        site should use first element, second instance should use second
        element, etc.

    """
    site_type_instances = {}
    for s in site_types.split(','):
        site_type, site_type_instance = s.split('/')

        if site_type not in site_type_instances:
            site_type_instances[site_type] = []

        site_type_instances[site_type].append(site_type_instance)

    return site_type_instances


def add_direct(xml, input, output):
    """ Add a direct tag to the interconnect_xml. """
    ET.SubElement(
        xml, 'direct', {
            'name': '{}_to_{}'.format(input, output),
            'input': input,
            'output': output
        }
    )


def write_xml(f, xml):
    """ Writes XML to disk. """
    pb_type_str = ET.tostring(xml, pretty_print=True).decode('utf-8')
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


def add_pinlocations(tile_name, import_tiles, xml, fc_xml, pin_assignments, wires):
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
    for phy_tile in import_tiles:
        for pin in wires:
            for side in pin_assignments['pin_directions'][phy_tile][pin]:
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


def start_pb_type(tile_name, import_tiles, f_pin_assignments, input_wires, output_wires):
    """ Starts a pb_type by adding input, clock and output tags. """
    pb_type_xml = ET.Element(
        'pb_type',
        {
            'name': add_vpr_tile_prefix(tile_name),
        },
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

    fc_xml = add_fc(pb_type_xml)

    pin_assignments = json.load(f_pin_assignments)
    add_pinlocations(
        tile_name, import_tiles, pb_type_xml, fc_xml, pin_assignments,
        input_wires | output_wires
    )

    pb_type_xml.append(ET.Comment(" Internal Sites "))

    return pb_type_xml

def site_id(site):
    return site.type + "." + site.name

def import_tile(db, args):
    """ Create a root-level pb_type with the pin names that match tile wires.

    This will either have 1 intermediate pb_type per site, or 1 large site
    for the entire tile if args.fused_sites is set to true.
    """

    import_tiles = []
    if args.import_tiles:
        import_tiles = set(args.import_tiles.split(','))
    else:
        import_tiles = {args.tile}

    sites = reduce(lambda acc, tile: acc + list(db.get_tile_type(tile).get_sites()), import_tiles, [])

    # Wires sink to a site within the tile are input wires.
    input_wires = set()

    # Wires source from a site within the tile are output wires.
    output_wires = set()

    inner_pins = {
        'ILOGICE3': {
            'D': ('IOB33M', 'I')
        },
        'OLOGICE3': {
            'OQ': ('IOB33M', 'O'),
            'TQ': ('IOB33M', 'T')
        },
        'IOB33M': {
            'I': ('ILOGICE3', 'D'),
            'O': ('OLOGICE3', 'OQ'),
            'T': ('OLOGICE3', 'TQ')
        },
    }

    if not args.fused_sites:
        site_type_instances = parse_site_type_instance(args.site_types)

        imported_site_types = set()
        ignored_site_types = set()

        for site in sites:
            site_type = db.get_site_type(site.type)
            site_inner_pins = inner_pins[site.type] if site.type in inner_pins else set()

            if site.type not in site_type_instances:
                ignored_site_types.add(site.type)
                continue

            imported_site_types.add(site.type)

            for site_pin in site.site_pins:
                site_type_pin = site_type.get_site_pin(site_pin.name)

                # omit site->site (IOI<->IOB) pins
                if site_pin.name in site_inner_pins:
                    continue

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
        for site in sites:
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

    site_pbtype = args.site_directory + "/{0}/{1}.pb_type.xml"

    ##########################################################################
    # Generate the model.xml file                                            #
    ##########################################################################

    model = ModelXml(f=args.output_model, site_directory=args.site_directory)

    if not args.fused_sites:
        site_types = set(site.type for site in sites)
        for site_type in site_types:
            if site_type in ignored_site_types:
                continue

            for instance in site_type_instances[site_type]:
                model.add_model_include(site_type, instance)
    else:
        fused_site_name = args.tile.lower()

        model.add_model_include(fused_site_name, fused_site_name)

    model.write_model()

    ##########################################################################
    # Utility functions for pb_type                                          #
    ##########################################################################
    tile_name = args.tile

    pb_type_xml = start_pb_type(
        tile_name, import_tiles, args.pin_assignments, input_wires, output_wires
    )

    cell_names = {}

    interconnect_xml = ET.Element('interconnect')

    if not args.fused_sites:
        site_type_count = {}
        site_prefixes = {}
        cells_idx = dict()

        site_type_ports = {}
        for site in sites:
            if site.type in ignored_site_types:
                continue

            if args.select_y is not None and args.select_y != site.y:
                continue

            if site.type not in site_type_count:
                site_type_count[site.type] = 0
                site_prefixes[site.type] = []

            cell_idx = site_type_count[site.type]
            cells_idx[site_id(site)] = cell_idx
            site_type_count[site.type] += 1
            site_prefix = '{}_X{}'.format(site.type, site.x)

            site_instance = site_type_instances[site.type][cell_idx]

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

            # assert site_instance not in site_type_ports, (
            #     site_instance, site_type_ports.keys()
            # )
            site_type_ports[site_instance] = ports

            attrib = dict(root_element.attrib)
            include_xml = ET.SubElement(pb_type_xml, 'pb_type', attrib)
            ET.SubElement(
                include_xml, XI_INCLUDE, {
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
                    metadata_xml, XI_INCLUDE, {
                        'href': site_type_path,
                        'xpointer': "xpointer(pb_type/metadata/child::node())",
                    }
                )

        for idx, site in enumerate(sites):
            if site.type in ignored_site_types:
                continue

            if args.select_y is not None and args.select_y != site.y:
                continue

            site_idx = cells_idx[site_id(site)]
            site_instance = site_type_instances[site.type][site_idx]
            site_name = cell_names[site_instance]

            site_type = db.get_site_type(site.type)

            site_inner_pins = inner_pins[site.type] if site.type in inner_pins else set()

            if args.generate_missing_pins:
                print("\nsite.type: {}".format(site.type))

            interconnect_xml.append(ET.Comment(" Tile->Site "))
            for site_pin in sorted(site.site_pins,
                                   key=lambda site_pin: site_pin.name):
                if site_pin.wire is None:
                    continue

                # omit site->site pins
                if site_pin.name in site_inner_pins:
                    continue

                port = find_port(site_pin.name, site_type_ports[site_instance])
                site_type_pin = site_type.get_site_pin(site_pin.name)

                if port is None:
                    if args.generate_missing_pins:
                        direction = "input" if site_type_pin.direction == prjxray.site_type.SitePinDirection.IN else "output"
                        print("<{} name=\"{}\" num_pins=\"1\"/>".format(direction, site_pin.name))
                    else:
                        print(
                            "*** WARNING *** Didn't find port for name {} for site type {}"
                            .format(site_pin.name, site.type),
                            file=sys.stderr
                        )
                    continue

                if site_type_pin.direction == prjxray.site_type.SitePinDirection.IN:
                    add_direct(
                        interconnect_xml,
                        input=object_ref(
                            add_vpr_tile_prefix(tile_name), site_pin.wire
                        ),
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

                # omit site->site pins
                if site_pin.name in site_inner_pins:
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
                        output=object_ref(
                            add_vpr_tile_prefix(tile_name), site_pin.wire
                        ),
                    )
                else:
                    assert False, site_type_pin.direction

        # connect site->site pins
        interconnect_xml.append(ET.Comment(" Site->Site "))
        for (site, pins) in inner_pins.items():
            site_type = db.get_site_type(site)
            for (pin, (other_site, other_pin)) in pins.items():
                site_type_pin = site_type.get_site_pin(pin)
                other_site_type = db.get_site_type(other_site)
                other_site_type_pin = other_site_type.get_site_pin(other_pin)

                if site_type_pin.direction == prjxray.site_type.SitePinDirection.IN:
                    add_direct(
                        interconnect_xml,
                        input=object_ref(other_site, other_pin),
                        output=object_ref(site, pin),
                    )
                elif site_type_pin.direction == prjxray.site_type.SitePinDirection.OUT:
                    pass
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
            include_xml, XI_INCLUDE, {
                'href': site_type_path,
                'xpointer': "xpointer(pb_type/child::node())",
            }
        )

        site_name = root_element.attrib['name']

        def fused_port_name(site, site_pin):
            return '{}_{}_{}'.format(site.prefix, site.name, site_pin.name)

        for idx, site in enumerate(sites):
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
                        input=object_ref(
                            add_vpr_tile_prefix(tile_name), site_pin.wire
                        ),
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
                        output=object_ref(
                            add_vpr_tile_prefix(tile_name), site_pin.wire
                        ),
                    )
                else:
                    assert False, site_type_pin.direction

    pb_type_xml.append(interconnect_xml)

    add_switchblock_locations(pb_type_xml)

    write_xml(args.output_pb_type, pb_type_xml)


def import_site_as_tile(db, args):
    """ Create a root-level pb_type with the same pin names as a site type.
    """
    site_type = db.get_site_type(args.tile)

    # Wires sink to a site within the tile are input wires.
    input_wires = set()

    # Wires source from a site within the tile are output wires.
    output_wires = set()

    site_type_instances = parse_site_type_instance(args.site_types)
    assert len(site_type_instances) == 1
    assert args.tile in site_type_instances
    assert len(site_type_instances[args.tile]) == 1

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
    model = ModelXml(f=args.output_model, site_directory=args.site_directory)
    model.add_model_include(args.tile, site_type_instances[args.tile][0])
    model.write_model()

    ##########################################################################
    # Generate the pb_type.xml file                                          #
    ##########################################################################

    tile_name = args.tile
    pb_type_xml = start_pb_type(
        tile_name, {tile_name}, args.pin_assignments, input_wires, output_wires
    )

    site = args.tile
    site_instance = site_type_instances[args.tile][0]

    site_pbtype = args.site_directory + "/{0}/{1}.pb_type.xml"
    site_type_path = site_pbtype.format(site.lower(), site_instance.lower())
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
                input=object_ref(add_vpr_tile_prefix(tile_name), site_pin),
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
                output=object_ref(add_vpr_tile_prefix(tile_name), site_pin),
            )
        else:
            assert False, site_type_pin.direction

    pb_type_xml.append(interconnect_xml)

    add_switchblock_locations(pb_type_xml)

    write_xml(args.output_pb_type, pb_type_xml)


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

    parser.add_argument('--import_tiles', help="""Comma seperated list of tiles to import, defaults to --tile if not set""")

    parser.add_argument('--select_y', type=int, help="""Select tiles with matching Y coordinate""")

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
        '--pin_assignments', required=True, type=argparse.FileType('r')
    )
    parser.add_argument(
        '--site_as_tile',
        action='store_true',
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

    parser.add_argument(
        '--generate_missing_pins',
        action='store_true',
        help="Print missing pin warnings as XML."
    )

    args = parser.parse_args()

    db = prjxray.db.Database(os.path.join(prjxray_db, args.part))

    ET.register_namespace('xi', XI_URL)
    if args.site_as_tile:
        assert not args.fused_sites
        import_site_as_tile(db, args)
    else:
        import_tile(db, args)


if __name__ == '__main__':
    main()
