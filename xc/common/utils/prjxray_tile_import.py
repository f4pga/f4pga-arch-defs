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
import sys
import prjxray.db
import prjxray.site_type
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
    assert name.startswith(VPR_TILE_PREFIX), name
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

    # check if signal name ends with number and has num_pins > 1
    # e.g. RXOSINTID0 which has num_pins=4, the real prefix is
    # RXOSINTID0 not RXOSINTID
    for p in ports.keys():
        if prefix in p and p.strip(prefix).isnumeric():
            prefix = p
            prefix_pin_idx = int(pin_name.replace(prefix, ""))

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


def start_pb_type(tile_name, f_pin_assignments, input_wires, output_wires):
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

    pb_type_xml.append(ET.Comment(" Internal Sites "))

    return pb_type_xml


def import_tile(db, args):
    """ Create a root-level pb_type with the pin names that match tile wires.

    This will either have 1 intermediate pb_type per site, or 1 large site
    for the entire tile if args.fused_sites is set to true.
    """

    tile = db.get_tile_type(args.tile)

    # Wires sink to a site within the tile are input wires.
    input_wires = set()

    # Wires source from a site within the tile are output wires.
    output_wires = set()

    if args.filter_x:
        xs = list(map(int, args.filter_x.split(',')))

        def x_filter_func(site):
            return site.x in xs

        x_filter = x_filter_func
    else:

        def x_filter_func(site):
            return True

        x_filter = x_filter_func

    if not args.fused_sites:
        site_type_instances = parse_site_type_instance(args.site_types)

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
                    if site.type != "PS7":
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

    site_pbtype = args.site_directory + "/{0}/{1}.pb_type.xml"

    ##########################################################################
    # Generate the model.xml file                                            #
    ##########################################################################

    model = ModelXml(f=args.output_model, site_directory=args.site_directory)

    if args.fused_sites:
        fused_site_name = args.tile.lower()

        model.add_model_include(fused_site_name, fused_site_name)

    ##########################################################################
    # Utility functions for pb_type                                          #
    ##########################################################################
    tile_name = args.tile

    pb_type_xml = start_pb_type(
        tile_name, args.pin_assignments, input_wires, output_wires
    )

    cell_names = {}

    interconnect_xml = ET.Element('interconnect')

    if not args.fused_sites:
        site_type_count = {}
        site_prefixes = {}
        cells_idx = {}
        models_added = set()

        site_type_ports = {}
        idx = 0
        for site in tile.get_sites():
            if site.type in ignored_site_types:
                continue

            if not x_filter(site):
                continue

            if site.type not in site_type_count:
                site_type_count[site.type] = 0
                site_prefixes[site.type] = []

            cells_idx[idx] = site_type_count[site.type]
            site_type_count[site.type] += 1

            site_coords = args.site_coords.upper()
            if site_coords == 'X':
                site_prefix = '{}_X{}'.format(site.type, site.x)
            elif site_coords == 'Y':
                site_prefix = '{}_Y{}'.format(site.type, site.y)
            elif site_coords == 'XY':
                site_prefix = '{}.{}_X{}Y{}'.format(
                    site.type, site.type, site.x, site.y
                )
            else:
                assert False, "Invalid --site-coords value '{}'".format(
                    site_coords
                )

            site_instance = site_type_instances[site.type][cells_idx[idx]]
            idx += 1

            if (site.type, site_instance) not in models_added:
                models_added.add((site.type, site_instance))
                model.add_model_include(site.type, site_instance)

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
                include_xml, XI_INCLUDE, {
                    'href':
                        site_type_path,
                    'xpointer':
                        "xpointer(pb_type/child::node()[local-name()!='metadata'])",
                }
            )

            metadata_xml = ET.SubElement(include_xml, 'metadata')

            if not args.no_fasm_prefix:
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

            # Prevent emitting empty metadata
            if not any(child.tag == 'meta' for child in metadata_xml):
                include_xml.remove(metadata_xml)

        idx = 0
        for site in tile.get_sites():
            if site.type in ignored_site_types:
                continue

            site_idx = cells_idx[idx]
            idx += 1

            if not x_filter(site):
                continue

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
                        input=object_ref(
                            add_vpr_tile_prefix(tile_name), site_pin.wire
                        ),
                        output=object_ref(site_name, **port)
                    )
                elif site_type_pin.direction == prjxray.site_type.SitePinDirection.OUT:
                    pass
                else:
                    if site.type != "PS7":
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
                        output=object_ref(
                            add_vpr_tile_prefix(tile_name), site_pin.wire
                        ),
                    )
                else:
                    if site.type != "PS7":
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

        for site in tile.get_sites():
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
                    if site.type != "PS7":
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
                    if site.type != "PS7":
                        assert False, site_type_pin.direction

    pb_type_xml.append(interconnect_xml)

    model.write_model()
    write_xml(args.output_pb_type, pb_type_xml)


def import_site_as_tile(db, args):
    """ Create a root-level pb_type with the same pin names as a site type.
    """
    site_type = db.get_site_type(args.tile)

    # Wires sink to a site within the tile are input wires.
    input_wires = set()

    # Wires source from a site within the tile are output wires.
    output_wires = set()

    # Wires unused for this tile (arch specific)
    unused_wires = list()
    drop_wires = list()
    if args.unused_wires:
        unused_wires = args.unused_wires.split(",")

    site_type_instances = parse_site_type_instance(args.site_types)
    assert len(site_type_instances) == 1
    assert args.tile in site_type_instances
    assert len(site_type_instances[args.tile]) == 1

    for site_pin in site_type.get_site_pins():
        site_type_pin = site_type.get_site_pin(site_pin)

        if site_type_pin.name in unused_wires:
            drop_wires.append(site_pin)
            continue
        if site_type_pin.direction == prjxray.site_type.SitePinDirection.IN:
            input_wires.add(site_type_pin.name)
        elif site_type_pin.direction == prjxray.site_type.SitePinDirection.OUT:
            output_wires.add(site_type_pin.name)
        else:
            assert False, site_type_pin.direction

    for wire in drop_wires:
        del site_type.site_pins[wire]

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
        tile_name, args.pin_assignments, input_wires, output_wires
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

    ports = {}
    for inputs in root_element.iter('input'):
        ports[inputs.attrib['name']] = int(inputs.attrib['num_pins'])

    for clocks in root_element.iter('clock'):
        ports[clocks.attrib['name']] = int(clocks.attrib['num_pins'])

    for outputs in root_element.iter('output'):
        ports[outputs.attrib['name']] = int(outputs.attrib['num_pins'])

    interconnect_xml = ET.Element('interconnect')

    interconnect_xml.append(ET.Comment(" Tile->Site "))
    for site_pin in sorted(site_type.get_site_pins()):
        site_type_pin = site_type.get_site_pin(site_pin)

        port = find_port(site_type_pin.name, ports)
        if port is None:
            print(
                "*** WARNING *** Didn't find port for name {} for site type {}"
                .format(site_type_pin.name, site_type.type),
                file=sys.stderr
            )
            continue

        if site_type_pin.direction == prjxray.site_type.SitePinDirection.IN:
            add_direct(
                interconnect_xml,
                input=object_ref(add_vpr_tile_prefix(tile_name), site_pin),
                output=object_ref(site_name, **port)
            )
        elif site_type_pin.direction == prjxray.site_type.SitePinDirection.OUT:
            pass
        else:
            assert False, site_type_pin.direction

    interconnect_xml.append(ET.Comment(" Site->Tile "))
    for site_pin in sorted(site_type.get_site_pins()):
        site_type_pin = site_type.get_site_pin(site_pin)

        port = find_port(site_type_pin.name, ports)
        if port is None:
            print(
                "*** WARNING *** Didn't find port for name {} for site type {}"
                .format(site_type_pin.name, site_type),
                file=sys.stderr
            )
            continue

        if site_type_pin.direction == prjxray.site_type.SitePinDirection.IN:
            pass
        elif site_type_pin.direction == prjxray.site_type.SitePinDirection.OUT:
            add_direct(
                interconnect_xml,
                input=object_ref(site_name, **port),
                output=object_ref(add_vpr_tile_prefix(tile_name), site_pin),
            )
        else:
            assert False, site_type_pin.direction

    pb_type_xml.append(interconnect_xml)

    write_xml(args.output_pb_type, pb_type_xml)


def expand_nodes_in_tile_type(conn, tile_type_pkey):
    cur = conn.cursor()
    cur.execute(
        """
CREATE TEMP TABLE phy_tiles AS
SELECT tile_map.phy_tile_pkey
FROM tile_map
INNER JOIN phy_tile
ON phy_tile.pkey = tile_map.phy_tile_pkey
WHERE tile_map.tile_pkey IN (
    SELECT pkey FROM tile WHERE tile_type_pkey = ?
)
GROUP BY phy_tile.tile_type_pkey;""", (tile_type_pkey, )
    )

    # Set of node pkeys to expand
    cur.execute(
        """
SELECT DISTINCT node_pkey
FROM wire
WHERE phy_tile_pkey IN (SELECT phy_tile_pkey FROM phy_tiles);"""
    )
    nodes_to_expand = set(node_pkey for (node_pkey, ) in cur)

    nodes_to_set = {}

    while len(nodes_to_expand) > 0:
        node_pkey = nodes_to_expand.pop()

        node_set = nodes_to_set.get(node_pkey, set((node_pkey, )))
        nodes_to_set[node_pkey] = node_set

        cur.execute(
            """
WITH
other_wires(phy_tile_pkey, pip_in_tile_pkey, other_wire_in_tile_pkey) AS (
    SELECT
      wire.phy_tile_pkey, undirected_pips.pip_in_tile_pkey, undirected_pips.other_wire_in_tile_pkey
    FROM undirected_pips
    INNER JOIN wire
    ON wire.wire_in_tile_pkey = undirected_pips.wire_in_tile_pkey
    INNER JOIN pip_in_tile
    ON pip_in_tile.pkey = undirected_pips.pip_in_tile_pkey
    WHERE
        wire.node_pkey = ?
    AND
        NOT pip_in_tile.is_pseudo
)
SELECT wire.node_pkey
FROM wire
INNER JOIN other_wires
ON
    wire.wire_in_tile_pkey = other_wires.other_wire_in_tile_pkey
AND
    wire.phy_tile_pkey = other_wires.phy_tile_pkey
WHERE
    wire.phy_tile_pkey IN (SELECT phy_tile_pkey FROM phy_tiles);""",
            (node_pkey, )
        )

        # Update node sets
        for (other_node_pkey, ) in cur:
            node_set |= nodes_to_set.get(
                other_node_pkey, set((other_node_pkey, ))
            )

        # Merge node sets
        for node_pkey in node_set:
            nodes_to_set[node_pkey] = node_set

    unique_node_sets = {}
    for node_set in nodes_to_set.values():
        if id(node_set) not in unique_node_sets:
            unique_node_sets[id(node_set)] = node_set

    if False:
        # Print node sets for debugging and inspection.
        for node_set in unique_node_sets.values():
            print()
            print(id(node_set), len(node_set))
            for node_pkey in node_set:
                cur.execute(
                    """
SELECT name
FROM wire_in_tile
WHERE pkey IN (
    SELECT wire.wire_in_tile_pkey
    FROM wire
    WHERE node_pkey = ?
    )""", (node_pkey, )
                )
                print(node_pkey, ' '.join(name for (name, ) in cur))

    cur.execute("""DROP TABLE phy_tiles""")

    return unique_node_sets.values()


def find_connections(conn, input_wires, output_wires, tile_type_pkey):
    """ Remove top-level ports only connected to internal sources and generates
    tile internal connections."""

    # Create connected node sets
    node_sets = list(expand_nodes_in_tile_type(conn, tile_type_pkey))

    # Number of site external connections for ports
    is_top_level_pin_external = {}
    for wire in input_wires:
        is_top_level_pin_external[wire] = False

    for wire in output_wires:
        is_top_level_pin_external[wire] = False

    internal_connections = {}
    top_level_connections = {}

    wire_to_site_pin = {}

    cur = conn.cursor()
    for node_set in node_sets:
        ipin_count = 0
        opin_count = 0
        node_set_has_external = False

        pins_used_in_node_sets = set()
        input_pins = set()
        output_pins = set()

        for node_pkey in node_set:
            cur.execute(
                """
SELECT
tile.tile_type_pkey, wire_in_tile.name, site_type.name, site_pin.name, site_pin.direction, count()
FROM wire
INNER JOIN wire_in_tile
ON wire.wire_in_tile_pkey = wire_in_tile.pkey
INNER JOIN site_pin
ON site_pin.pkey = wire_in_tile.site_pin_pkey
INNER JOIN tile
ON wire.tile_pkey = tile.pkey
INNER JOIN site_type
ON site_type.pkey = site_pin.site_type_pkey
WHERE
    wire.node_pkey = ?
AND
    wire_in_tile.site_pin_pkey IS NOT NULL
GROUP BY site_pin.direction;
        """, (node_pkey, )
            )
            for wire_tile_type_pkey, wire_name, site_type_name, site_pin_name, dir, count in cur:
                if wire_tile_type_pkey == tile_type_pkey:
                    value = (site_type_name, site_pin_name)
                    if wire_name in wire_to_site_pin:
                        assert value == wire_to_site_pin[wire_name], (
                            wire_name, value, wire_to_site_pin[wire_name]
                        )
                    else:
                        wire_to_site_pin[wire_name] = value

                    pins_used_in_node_sets.add(wire_name)
                    direction = prjxray.site_type.SitePinDirection(dir)

                    if direction == prjxray.site_type.SitePinDirection.IN:
                        output_pins.add(wire_name)
                        opin_count += count
                    elif direction == prjxray.site_type.SitePinDirection.OUT:
                        input_pins.add(wire_name)
                        ipin_count += count
                    else:
                        assert False, (node_pkey, direction)
                else:
                    node_set_has_external = True

        assert len(input_pins) in [0, 1], input_pins

        if ipin_count == 0 or opin_count == 0 or node_set_has_external:
            # This node set is connected externally, mark as such
            for wire_name in pins_used_in_node_sets:
                is_top_level_pin_external[wire_name] = True

        if ipin_count > 0 and opin_count > 0:
            # TODO: Add check that pips and site pins on these internal
            # connections are 0 delay.
            assert len(input_pins) == 1
            input_wire = input_pins.pop()

            for wire_name in output_pins:
                if wire_name in internal_connections:
                    assert input_wire == internal_connections[wire_name]
                else:
                    internal_connections[wire_name] = input_wire

    for wire in sorted(is_top_level_pin_external):
        if not is_top_level_pin_external[wire]:
            if wire in input_wires:
                input_wires.remove(wire)
            elif wire in output_wires:
                output_wires.remove(wire)
            else:
                assert False, wire
        else:
            top_level_connections[wire] = wire_to_site_pin[wire]

    output_internal_connections = {}
    for output_wire in internal_connections:
        output_internal_connections[wire_to_site_pin[output_wire]
                                    ] = wire_to_site_pin[
                                        internal_connections[output_wire]]

    return top_level_connections, output_internal_connections


def get_tile_prefix(conn, tile_type_pkey, site_type):
    cur = conn.cursor()

    cur.execute(
        """
SELECT tile_type.name
FROM tile_type
WHERE pkey IN (
  SELECT tile_type.pkey
  FROM tile_type
  INNER JOIN site
  ON site.tile_type_pkey = tile_type.pkey
  INNER JOIN site_type
  ON site_type.pkey = site.site_type_pkey
  WHERE
    site_type.name = ?
  AND
    tile_type.pkey IN (
      SELECT DISTINCT phy_tile.tile_type_pkey
      FROM phy_tile
      INNER JOIN tile_map
      ON phy_tile.pkey = tile_map.phy_tile_pkey
      WHERE tile_map.tile_pkey IN (
        SELECT tile.pkey
        FROM tile
        WHERE tile.tile_type_pkey = ?
      )
  )
);""", (site_type, tile_type_pkey)
    )
    results = list(cur.fetchall())

    assert len(results) > 0, (tile_type_pkey, site_type)

    # Use shortest variant of tile type, under the assumption that this is
    # the most common.
    #
    # Example:
    #
    # Between RIOI3, RIOI3_TBYTESRC, and RIOI3_TBYTETERM, use RIOI3.
    min_tile_type = min(tile_type for (tile_type, ) in results)

    return '{' + min_tile_type + '}'


# prjxray segbits use site names without the version suffix.
NORMALIZED_SITE_TYPES = {
    "IOB33M": "IOB",
    "IOB33S": "IOB",
    "IOB33": "IOB",
    "ILOGICE3": "ILOGIC",
    "OLOGICE3": "OLOGIC",
    "IDELAYE2": "IDELAY",
}


def normalize_site_type(site_type):
    return NORMALIZED_SITE_TYPES.get(site_type, site_type)


def import_tile_from_database(conn, args):
    """ Create a root-level pb_type using the site pins and sites from the database.
    """

    # Wires sink to a site within the tile are input wires.
    input_wires = set()

    # Wires source from a site within the tile are output wires.
    output_wires = set()

    cur = conn.cursor()
    cur2 = conn.cursor()

    cur.execute("SELECT pkey FROM tile_type WHERE name = ?", (args.tile, ))
    tile_type_pkey = cur.fetchone()[0]

    # Find instances of sites, sorted by their original tile type.
    # Then choice the first of each site type as the wire set.
    # This ensures a unique and internally consistent site set for analyzing
    # connectivity.
    #
    # Note:  This does assume that only one instance of each site is present
    # in each tile, which is checked.
    sites = {}
    sites_in_tiles = set()
    cur.execute(
        """
SELECT
    site.site_type_pkey, wire_in_tile.site_pkey, wire_in_tile.phy_tile_type_pkey
FROM wire_in_tile
INNER JOIN site
ON site.pkey = wire_in_tile.site_pkey
WHERE
    wire_in_tile.tile_type_pkey = ?
GROUP BY site.site_type_pkey, wire_in_tile.phy_tile_type_pkey
ORDER BY wire_in_tile.phy_tile_type_pkey;""", (tile_type_pkey, )
    )
    for site_type_pkey, site_pkey, phy_tile_type_pkey in cur:
        if site_type_pkey not in sites:
            sites[site_type_pkey] = site_pkey

        # Verify that assumption that each site type is only used once per tile
        # is true.
        key = (site_type_pkey, phy_tile_type_pkey)
        assert key not in sites_in_tiles, key
        sites_in_tiles.add(key)

    # Retrieve initial top-level port names
    top_level_pins = {}
    for site_pkey in sites.values():
        for wire_in_tile_pkey, wire_name, direction in cur.execute("""
SELECT
    wire_in_tile.pkey, wire_in_tile.name, site_pin.direction
FROM wire_in_tile
INNER JOIN site_pin
ON wire_in_tile.site_pin_pkey = site_pin.pkey
WHERE
    site_pkey = ?""", (site_pkey, )):
            direction = prjxray.site_type.SitePinDirection(direction)

            assert wire_name not in top_level_pins
            top_level_pins[wire_name] = (site_pkey, wire_in_tile_pkey)

            if direction == prjxray.site_type.SitePinDirection.IN:
                assert wire_name not in input_wires
                input_wires.add(wire_name)
            elif direction == prjxray.site_type.SitePinDirection.OUT:
                assert wire_name not in output_wires
                output_wires.add(wire_name)
            else:
                assert False, wire_name

    ##########################################################################
    # Generate the model.xml file                                            #
    ##########################################################################
    model = ModelXml(f=args.output_model, site_directory=args.site_directory)
    site_type_instances = parse_site_type_instance(args.site_types)

    for site_type_pkey in sites:
        cur.execute(
            "SELECT name FROM site_type WHERE pkey = ?", (site_type_pkey, )
        )
        site_type = cur.fetchone()[0]
        for instance in site_type_instances[site_type]:
            model.add_model_include(site_type, instance)
    model.write_model()

    # Determine which input/output wires connection to other site pins, and no
    # others.
    top_level_connections, internal_connections = find_connections(
        conn, input_wires, output_wires, tile_type_pkey
    )

    ##########################################################################
    # Generate the pb_type.xml file                                          #
    ##########################################################################

    tile_name = args.tile
    pb_type_xml = start_pb_type(
        tile_name, args.pin_assignments, input_wires, output_wires
    )

    cell_names = {}

    interconnect_xml = ET.Element('interconnect')

    site_pbtype = args.site_directory + "/{0}/{1}.pb_type.xml"

    site_type_count = {}
    site_prefixes = {}
    cells_idx = []

    ignored_site_types = set()

    cur.execute(
        """
WITH tiles_per_tile(num_tiles) AS (
  SELECT count()
  FROM tile_map
  INNER JOIN tile
  ON tile_map.tile_pkey = tile.pkey
  WHERE tile.tile_type_pkey = ?
  GROUP BY tile_map.tile_pkey
)
SELECT max(num_tiles) FROM tiles_per_tile;
        """, (tile_type_pkey, )
    )
    max_tile_count = cur.fetchone()[0]
    need_tile_prefixs = max_tile_count > 1

    site_type_ports = {}
    cur.execute(
        """
SELECT DISTINCT
  site_type.name, site_instance.y_coord % 2
FROM
  site
INNER JOIN
  site_type
ON site.site_type_pkey = site_type.pkey
INNER JOIN
  site_instance
ON site.pkey = site_instance.site_pkey
WHERE
  site.pkey IN (
    SELECT
      DISTINCT site_pkey
    FROM
      wire_in_tile
    WHERE
      tile_type_pkey = ?
      AND site_pin_pkey IS NOT NULL
  )
    """, (tile_type_pkey, )
    )
    for idx, (site_type, site_y) in enumerate(cur):
        if site_type in ignored_site_types:
            continue

        if site_type not in site_type_count:
            site_type_count[site_type] = 0
            site_prefixes[site_type] = []

        cells_idx.append(site_type_count[site_type])
        site_type_count[site_type] += 1
        site_prefix = '{}_Y{}'.format(normalize_site_type(site_type), site_y)

        # When tiles are merged, additional tile prefixes are required here
        # to disambiguate which physical tile this site belongs too
        if need_tile_prefixs:
            tile_prefix = get_tile_prefix(conn, tile_type_pkey, site_type)
            site_prefix = '{}.{}'.format(tile_prefix, site_prefix)

        site_instance = site_type_instances[site_type][cells_idx[idx]]

        site_type_path = site_pbtype.format(
            site_type.lower(), site_instance.lower()
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
            include_xml, XI_INCLUDE, {
                'href':
                    site_type_path,
                'xpointer':
                    "xpointer(pb_type/child::node()[local-name()!='metadata'])",
            }
        )

        metadata_xml = ET.SubElement(include_xml, 'metadata')

        if not args.no_fasm_prefix:
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

        # Prevent emitting empty metadata
        if not any(child.tag == 'meta' for child in metadata_xml):
            include_xml.remove(metadata_xml)

    # Iterate over sites in tile
    cur.execute(
        """
SELECT
  site_type.name,
  site.pkey
FROM
  site
  INNER JOIN site_type ON site.site_type_pkey = site_type.pkey
WHERE
  site.pkey IN (
    SELECT
      DISTINCT site_pkey
    FROM
      wire_in_tile
    WHERE
      tile_type_pkey = ?
      AND site_pin_pkey IS NOT NULL
  )
GROUP BY
  site.site_type_pkey,
  site.x_coord,
  site.y_coord
    """, (tile_type_pkey, )
    )
    for idx, (site_type, site_pkey) in enumerate(cur):
        if site_type in ignored_site_types:
            continue

        site_idx = cells_idx[idx]
        site_instance = site_type_instances[site_type][site_idx]
        site_name = cell_names[site_instance]

        interconnect_xml.append(ET.Comment(" Tile->Site "))

        # Iterate over pins in site
        cur2.execute(
            """
SELECT
  site_pin.name,
  site_pin.direction,
  wire_in_tile.name
FROM
  wire_in_tile
  INNER JOIN site_pin ON wire_in_tile.site_pin_pkey = site_pin.pkey
WHERE
  wire_in_tile.tile_type_pkey = ?
  AND wire_in_tile.site_pkey = ?
  AND wire_in_tile.site_pin_pkey IS NOT NULL;
        """, (tile_type_pkey, site_pkey)
        )
        site_pins = list(cur2)
        for site_pin_name, site_pin_direction, site_pin_wire in site_pins:
            site_pin_direction = prjxray.site_type.SitePinDirection(
                site_pin_direction
            )
            port = find_port(site_pin_name, site_type_ports[site_instance])
            if port is None:
                print(
                    "*** WARNING *** Didn't find port for name {} for site type {}"
                    .format(site_pin_name, site_type),
                    file=sys.stderr
                )
                continue

            # Sanity check top_level_connections
            if site_pin_wire not in top_level_connections:
                continue

            assert top_level_connections[site_pin_wire] == (
                site_type, site_pin_name
            )

            if site_pin_direction == prjxray.site_type.SitePinDirection.IN:
                add_direct(
                    interconnect_xml,
                    input=object_ref(
                        add_vpr_tile_prefix(tile_name), site_pin_wire
                    ),
                    output=object_ref(site_name, **port)
                )
            elif site_pin_direction == prjxray.site_type.SitePinDirection.OUT:
                pass
            else:
                assert False, site_pin_direction

        interconnect_xml.append(ET.Comment(" Site->Tile "))

        # Iterate over pins in site
        cur2.execute("")
        for site_pin_name, site_pin_direction, site_pin_wire in site_pins:
            site_pin_direction = prjxray.site_type.SitePinDirection(
                site_pin_direction
            )
            port = find_port(site_pin_name, site_type_ports[site_instance])
            if port is None:
                continue

            # Sanity check top_level_connections
            if site_pin_wire not in top_level_connections:
                continue

            assert top_level_connections[site_pin_wire] == (
                site_type, site_pin_name
            )

            if site_pin_direction == prjxray.site_type.SitePinDirection.IN:
                pass
            elif site_pin_direction == prjxray.site_type.SitePinDirection.OUT:
                add_direct(
                    interconnect_xml,
                    input=object_ref(site_name, **port),
                    output=object_ref(
                        add_vpr_tile_prefix(tile_name), site_pin_wire
                    ),
                )
            else:
                assert False, site_pin_direction

    interconnect_xml.append(ET.Comment(" Site->Site "))

    for (dest_site_type, dest_site_pin_name), (src_site_type, src_site_pin_name) in \
            sorted(internal_connections.items(), key=lambda x: (x[1], x[0])):
        # Only handling single instance per site type right now
        assert len(site_type_instances[src_site_type]) == 1
        assert len(site_type_instances[dest_site_type]) == 1

        src_site_instance = site_type_instances[src_site_type][0]
        src_port = find_port(
            src_site_pin_name, site_type_ports[src_site_instance]
        )
        src_site_name = cell_names[src_site_instance]
        if src_port is None:
            print(
                "*** WARNING *** Didn't find port for name {} for site type {}"
                .format(src_site_pin_name, src_site_type),
                file=sys.stderr
            )
            continue

        dest_site_instance = site_type_instances[dest_site_type][0]
        dest_port = find_port(
            dest_site_pin_name, site_type_ports[dest_site_instance]
        )
        dest_site_name = cell_names[dest_site_instance]
        if dest_port is None:
            print(
                "*** WARNING *** Didn't find port for name {} for site type {}"
                .format(dest_site_pin_name, dest_site_type),
                file=sys.stderr
            )
            continue

        add_direct(
            interconnect_xml,
            input=object_ref(src_site_name, **src_port),
            output=object_ref(dest_site_name, **dest_port),
        )

    pb_type_xml.append(interconnect_xml)

    write_xml(args.output_pb_type, pb_type_xml)


def main():
    parser = argparse.ArgumentParser(
        description=__doc__, fromfile_prefix_chars='@', prefix_chars='-~'
    )

    parser.add_argument('--db_root', help="""Project X-Ray database to use.""")

    parser.add_argument('--part', help="""FPGA part to use.""")

    parser.add_argument('--tile', help="""Tile to generate for""")

    parser.add_argument(
        '--site_directory', help="""Diretory where sites are defined"""
    )

    parser.add_argument(
        '--site_coords',
        type=str,
        default='X',
        help="""Specify which site coords to use ('X', 'Y' or 'XY')"""
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
        help="""
Typically a tile can treat the sites within the tile as independent.
For tiles where this is not true, fused sites only imports 1 primatative
for the entire tile, which should be named the same as the tile type."""
    )

    parser.add_argument(
        '--connection_database',
        help="""
Location of connection database to define this tile type.
The tile will be defined by the sites and wires from the
connection database in lue of Project X-Ray."""
    )

    parser.add_argument(
        '--filter_x', help="Filter imported sites by their x coordinate."
    )

    parser.add_argument(
        '--no_fasm_prefix',
        action="store_true",
        help="""Do not insert fasm prefix to the metadata."""
    )

    parser.add_argument(
        '--unused_wires',
        help="Comma seperated list of site wires to exclude in this tile."
    )

    args = parser.parse_args()

    db = prjxray.db.Database(args.db_root, args.part)

    ET.register_namespace('xi', XI_URL)
    if args.site_as_tile:
        assert not args.fused_sites
        import_site_as_tile(db, args)
    elif args.connection_database:
        with sqlite3.connect("file:{}?mode=ro".format(
                args.connection_database), uri=True) as conn:
            import_tile_from_database(conn, args)
    else:
        import_tile(db, args)


if __name__ == '__main__':
    main()
