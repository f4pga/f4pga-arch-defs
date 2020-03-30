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
import sqlite3

import lxml.etree as ET
from lib.pb_type_xml import (
    start_pb_type, start_tile, add_vpr_tile_prefix, add_tile_direct,
    object_ref, add_switchblock_locations, write_xml, ModelXml, add_direct,
    XI_INCLUDE, XI_URL
)


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
        wire.phy_tile_pkey,
        undirected_pips.pip_in_tile_pkey,
        undirected_pips.other_wire_in_tile_pkey
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
    tile.tile_type_pkey,
    wire_in_tile.name,
    site_type.name,
    site_pin.name,
    site_pin.direction,
    count()
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
            for (wire_tile_type_pkey, wire_name, site_type_name, site_pin_name,
                 direction, count) in cur:
                if wire_tile_type_pkey == tile_type_pkey:
                    value = (site_type_name, site_pin_name)
                    if wire_name in wire_to_site_pin:
                        assert value == wire_to_site_pin[wire_name], (
                            wire_name, value, wire_to_site_pin[wire_name]
                        )
                    else:
                        wire_to_site_pin[wire_name] = value

                    pins_used_in_node_sets.add(wire_name)
                    direction = prjxray.site_type.SitePinDirection(direction)

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
        output_internal_connections[wire_to_site_pin[output_wire]] = \
            wire_to_site_pin[internal_connections[output_wire]]

    return top_level_connections, output_internal_connections


NORMALIZED_TILE_TYPES = {
    "RIOI3": "IOI3_TILE",
    "RIOI3_SING": "IOI3_TILE",
    "RIOI3_TBYTESRC": "IOI3_TILE",
    "RIOI3_TBYTETERM": "IOI3_TILE",
    "LIOI3": "IOI3_TILE",
    "LIOI3_SING": "IOI3_TILE",
    "LIOI3_TBYTESRC": "IOI3_TILE",
    "LIOI3_TBYTETERM": "IOI3_TILE",
    "LIOB33": "IOB_TILE",
    "LIOB33_SING": "IOB_TILE",
    "RIOB33": "IOB_TILE",
    "RIOB33_SING": "IOB_TILE",
    "CMT_TOP_R_UPPER_T": "CMT_TOP_UPPER_T",
    "CMT_TOP_L_UPPER_T": "CMT_TOP_UPPER_T",
}

NORMALIZED_SITE_TYPES = {
    "IOB33M": "IOB",
    "IOB33S": "IOB",
    "IOB33": "IOB",
    "ILOGICE3": "ILOGIC",
    "OLOGICE3": "OLOGIC",
    "IDELAYE2": "IDELAY",
}


def get_tile_prefixes(conn, tile_type_pkeys, site_types, site_remap):
    cur = conn.cursor()

    tile_prefixes = {}

    for tile_type_pkey in tile_type_pkeys:
        cur.execute(
            """
SELECT
  DISTINCT tile_type.name, site_type.pkey, site_type.name
FROM
  wire_in_tile
INNER JOIN tile_type ON tile_type.pkey = wire_in_tile.phy_tile_type_pkey
INNER JOIN site ON site.pkey = wire_in_tile.site_pkey
INNER JOIN site_type ON site_type.pkey = site.site_type_pkey
WHERE
  wire_in_tile.tile_type_pkey = ?
  AND site_pin_pkey IS NOT NULL;
""", (tile_type_pkey, )
        )
        for tile_type_name, site_type_pkey, site_type_name in cur:
            norm_tile = NORMALIZED_TILE_TYPES.get(
                tile_type_name, tile_type_name
            )
            if site_type_pkey not in site_types:
                new_site_type_pkey = site_remap[site_type_pkey]
                assert new_site_type_pkey in site_types
                site_type_pkey = new_site_type_pkey

            norm_site = NORMALIZED_SITE_TYPES.get(
                site_type_name, site_type_name
            )

            prefix = '{' + norm_tile + '}.{' + norm_site + '}'

            if site_type_pkey in tile_prefixes:
                assert prefix == tile_prefixes[site_type_pkey], (
                    prefix, tile_prefixes[site_type_pkey]
                )
            else:
                tile_prefixes[site_type_pkey] = prefix

    return tile_prefixes


def sites_in_tile_type(conn, tile_type_pkey):
    cur = conn.cursor()

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

    return sites, sites_in_tiles


def yield_mapped_site_sets(site_remaps, site_type_pkeys):
    yield frozenset(
        site_remaps.get(site_type_pkey, site_type_pkey)
        for site_type_pkey in site_type_pkeys
    )


def check_site_equiv(conn, general_site_type_pkey, specific_site_type_pkey):
    """ Verify assumption that site pin names on specific site are subset of general site.

    E.g. every pin on the specific site should be present on the generic site.

    """
    cur = conn.cursor()

    cur.execute(
        "SELECT name FROM site_pin WHERE site_type_pkey = ?",
        (general_site_type_pkey, )
    )
    general_site_pins = set(name for (name, ) in cur)

    cur.execute(
        "SELECT name FROM site_pin WHERE site_type_pkey = ?",
        (specific_site_type_pkey, )
    )
    for (name, ) in cur:
        assert name in general_site_pins, (
            general_site_pins, name, specific_site_type_pkey
        )


def create_pb_type(
        conn, pin_assignments, site_directory, output_directory, pb_type,
        site_type_pkeys, tile_type_pkeys, site_remaps, site_name_remaps,
        node_tile_map
):
    cur = conn.cursor()
    cur2 = conn.cursor()

    wire_to_site_pin = {}
    internal_connections = {}
    top_level_pin_external = set()
    top_level_wire_external = set()

    all_pb_type_input_pins = None
    all_pb_type_output_pins = None

    for tile_type_pkey in tile_type_pkeys:
        pb_type_input_pins = set()
        pb_type_output_pins = set()

        for node_set in node_tile_map[tile_type_pkey]:
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
    tile.tile_type_pkey,
    wire_in_tile.name,
    site_type.pkey,
    site_type.name,
    site_pin.name,
    site_pin.direction,
    count()
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
                for (wire_tile_type_pkey, wire_name, site_type_pkey,
                     site_type_name, site_pin_name, direction, count) in cur:

                    if wire_tile_type_pkey == tile_type_pkey:
                        if site_type_pkey not in site_type_pkeys:
                            # Remap if a mapping exists
                            site_type_name = site_name_remaps.get(
                                site_type_name, site_type_name
                            )
                            cur2.execute(
                                "SELECT pkey FROM site_type WHERE name = ?",
                                (site_type_name, )
                            )
                            new_site_type_pkey = cur2.fetchone()[0]
                            assert new_site_type_pkey in site_type_pkeys, (
                                pb_type, tile_type_pkey, node_pkey,
                                site_type_pkey, new_site_type_pkey,
                                site_type_pkeys, site_type_name
                            )

                        direction = prjxray.site_type.SitePinDirection(
                            direction
                        )
                        value = (site_type_name, site_pin_name, direction)
                        if wire_name in wire_to_site_pin:
                            assert value == wire_to_site_pin[wire_name], (
                                wire_name, value, wire_to_site_pin[wire_name]
                            )
                        else:
                            wire_to_site_pin[wire_name] = value

                        pins_used_in_node_sets.add(
                            (wire_name, site_type_name, site_pin_name)
                        )

                        if direction == prjxray.site_type.SitePinDirection.IN:
                            output_pins.add(wire_name)
                            pb_type_output_pins.add(
                                (site_type_name, site_pin_name)
                            )
                            opin_count += count
                        elif direction == prjxray.site_type.SitePinDirection.OUT:
                            input_pins.add(wire_name)
                            pb_type_input_pins.add(
                                (site_type_name, site_pin_name)
                            )
                            ipin_count += count
                        else:
                            assert False, (node_pkey, direction)
                    else:
                        node_set_has_external = True

            assert len(input_pins) in [0, 1], input_pins

            if ipin_count == 0 or opin_count == 0 or node_set_has_external or len(
                    site_type_pkeys) == 1:
                # This node set is connected externally, mark as such
                for wire_name, site_type_name, site_pin_name in pins_used_in_node_sets:
                    top_level_wire_external.add(wire_name)
                    top_level_pin_external.add((site_type_name, site_pin_name))

            if len(site_type_pkeys) == 1:
                continue

            if ipin_count > 0 and opin_count > 0:
                # TODO: Add check that pips and site pins on these internal
                # connections are 0 delay.
                assert len(input_pins) == 1
                input_wire = input_pins.pop()

                for wire_name in output_pins:
                    k = wire_to_site_pin[wire_name]
                    v = wire_to_site_pin[input_wire]
                    if k in internal_connections:
                        assert v == internal_connections[k], (
                            v, internal_connections[k]
                        )
                    else:
                        internal_connections[k] = v

        pb_type_input_pins = set(
            v for v in pb_type_input_pins if v in top_level_pin_external
        )
        pb_type_output_pins = set(
            v for v in pb_type_output_pins if v in top_level_pin_external
        )

        if all_pb_type_input_pins is None:
            all_pb_type_input_pins = pb_type_input_pins
            all_pb_type_output_pins = pb_type_output_pins
        else:
            all_pb_type_input_pins &= pb_type_input_pins
            all_pb_type_output_pins &= pb_type_output_pins

    ##########################################################################
    # Generate the model.xml file                                            #
    ##########################################################################
    model = ModelXml(
        f=os.path.join(
            output_directory, pb_type.lower(),
            '{}.model.xml'.format(pb_type.lower())
        ),
        site_directory=site_directory
    )

    for site_type_pkey in site_type_pkeys:
        cur.execute(
            "SELECT name FROM site_type WHERE pkey = ?", (site_type_pkey, )
        )
        site_type = cur.fetchone()[0]
        model.add_model_include(site_type, site_type)
    model.write_model()

    ##########################################################################
    # Generate the pb_type.xml file                                          #
    ##########################################################################

    pb_type_xml = start_pb_type(
        pb_type,
        pin_assignments,
        ['{}_{}'.format(site, pin) for site, pin in all_pb_type_output_pins],
        ['{}_{}'.format(site, pin) for site, pin in all_pb_type_input_pins],
    )

    interconnect_xml = ET.Element('interconnect')

    site_pbtype = site_directory + "/{0}/{1}.pb_type.xml"

    site_prefixes = get_tile_prefixes(
        conn, tile_type_pkeys, site_type_pkeys, site_remaps
    )

    cell_names = {}
    site_type_ports = {}

    for site_type_pkey in site_type_pkeys:
        cur.execute(
            "SELECT name FROM site_type WHERE pkey = ?", (site_type_pkey, )
        )
        site_type = cur.fetchone()[0]
        site_prefix = site_prefixes[site_type_pkey]
        site_type_path = site_pbtype.format(
            site_type.lower(), site_type.lower()
        )

        cell_pb_type = ET.ElementTree()
        root_element = cell_pb_type.parse(site_type_path)
        cell_names[site_type] = root_element.attrib['name']

        ports = {}
        for inputs in root_element.iter('input'):
            ports[inputs.attrib['name']] = int(inputs.attrib['num_pins'])

        for clocks in root_element.iter('clock'):
            ports[clocks.attrib['name']] = int(clocks.attrib['num_pins'])

        for outputs in root_element.iter('output'):
            ports[outputs.attrib['name']] = int(outputs.attrib['num_pins'])

        assert site_type not in site_type_ports, (
            site_type, site_type_ports.keys()
        )
        site_type_ports[site_type] = ports

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
        if len(site_type_pkeys) > 1:
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

    for site_type, site_pin_name in top_level_pin_external:
        port = find_port(site_pin_name, site_type_ports[site_type])
        if port is None:
            print(
                "*** WARNING *** Didn't find port for name {} for site type {}"
                .format(site_pin_name, site_type),
                file=sys.stderr
            )
            continue

        site_name = cell_names[site_type]
        is_input = (site_type, site_pin_name) in all_pb_type_input_pins
        is_output = (site_type, site_pin_name) in all_pb_type_output_pins

        if not is_input and not is_output:
            continue

        if is_input:
            add_direct(
                interconnect_xml,
                input=object_ref(site_name, **port),
                output=object_ref(
                    add_vpr_tile_prefix(pb_type),
                    '{}_{}'.format(site_type, site_pin_name),
                ),
            )

    for site_type, site_pin_name in top_level_pin_external:
        port = find_port(site_pin_name, site_type_ports[site_type])
        if port is None:
            continue

        site_name = cell_names[site_type]
        is_input = (site_type, site_pin_name) in all_pb_type_input_pins
        is_output = (site_type, site_pin_name) in all_pb_type_output_pins

        if not is_input and not is_output:
            continue

        if is_output:
            add_direct(
                interconnect_xml,
                input=object_ref(
                    add_vpr_tile_prefix(pb_type),
                    '{}_{}'.format(site_type, site_pin_name)
                ),
                output=object_ref(site_name, **port),
            )

    for (dest_site_type, dest_site_pin_name, _), (src_site_type, src_site_pin_name, _) in \
            sorted(internal_connections.items(), key=lambda x: (x[1], x[0])):
        src_port = find_port(src_site_pin_name, site_type_ports[src_site_type])
        src_site_name = cell_names[src_site_type]
        if src_port is None:
            print(
                "*** WARNING *** Didn't find port for name {} for site type {}"
                .format(src_site_pin_name, src_site_type),
                file=sys.stderr
            )
            continue

        dest_port = find_port(
            dest_site_pin_name, site_type_ports[dest_site_type]
        )
        dest_site_name = cell_names[dest_site_type]
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

    write_xml(
        os.path.join(
            output_directory, pb_type.lower(),
            '{}.pb_type.xml'.format(pb_type.lower())
        ), pb_type_xml
    )

    top_level_connections = {}
    for wire in sorted(top_level_wire_external):
        site_type, site_pin_name, _ = wire_to_site_pin[wire]
        is_input = (site_type, site_pin_name) in all_pb_type_input_pins
        is_output = (site_type, site_pin_name) in all_pb_type_output_pins

        if not is_input and not is_output:
            continue

        top_level_connections[wire] = wire_to_site_pin[wire]

    return top_level_connections


def create_tile(
        conn, tile_type, tile_type_pkey, tile_connections, pb_types,
        pin_assignments, output_directory
):
    cur = conn.cursor()

    input_wires = set()
    output_wires = set()

    cur.execute(
        """
SELECT DISTINCT wire_in_tile.name
FROM wire_in_tile
WHERE
 wire_in_tile.tile_type_pkey = ?
AND
 wire_in_tile.site_pin_pkey IS NOT NULL;
    """, (tile_type_pkey, )
    )
    for (wire_name, ) in cur:
        for pb_type in pb_types:
            if wire_name in tile_connections[pb_type]:
                site_type_name, site_pin_name, direction = tile_connections[
                    pb_type][wire_name]

                if direction == prjxray.site_type.SitePinDirection.IN:
                    input_wires.add(wire_name)
                elif direction == prjxray.site_type.SitePinDirection.OUT:
                    output_wires.add(wire_name)
                else:
                    assert False, (wire_name, direction)

    tile_xml = start_tile(
        tile_type,
        pin_assignments,
        input_wires,
        output_wires,
    )

    equivalent_sites_xml = ET.Element('equivalent_sites')

    for pb_type in pb_types:
        site_xml = ET.Element(
            'site', {
                'pb_type': add_vpr_tile_prefix(pb_type),
                'pin_mapping': 'custom'
            }
        )
        equivalent_sites_xml.append(site_xml)

        for wire_name in input_wires | output_wires:
            if wire_name in tile_connections[pb_type]:
                site_type_name, site_pin_name, direction = tile_connections[
                    pb_type][wire_name]
                add_tile_direct(
                    site_xml,
                    tile=object_ref(
                        add_vpr_tile_prefix(tile_type),
                        wire_name,
                    ),
                    pb_type=object_ref(
                        add_vpr_tile_prefix(pb_type),
                        '{}_{}'.format(site_type_name, site_pin_name)
                    ),
                )

    sub_tile_xml = tile_xml.find('./sub_tile')

    sub_tile_xml.append(equivalent_sites_xml)

    add_switchblock_locations(tile_xml)

    write_xml(
        os.path.join(
            output_directory, tile_type.lower(),
            '{}.tile.xml'.format(tile_type.lower())
        ), tile_xml
    )


def main():
    parser = argparse.ArgumentParser(
        description=__doc__, fromfile_prefix_chars='@', prefix_chars='-~'
    )

    parser.add_argument(
        '--site_directory',
        required=True,
        help="""Diretory where sites are defined"""
    )

    parser.add_argument(
        '--output_directory',
        required=True,
        help="Directory to write output XML too.",
    )

    parser.add_argument(
        '--pin_assignments',
        required=True,
    )

    parser.add_argument(
        '--connection_database',
        required=True,
        help=(
            "Location of connection database to define this tile type.  " +
            "The tile will be defined by the sites and wires from the " +
            "connection database in lue of Project X-Ray."
        )
    )

    parser.add_argument(
        '--tile_types',
        required=True,
        help="Comma seperated list of tiles to create equivilance between."
    )

    parser.add_argument('--pb_types', nargs='+', required=True, help="")

    parser.add_argument(
        '--site_equivilances',
        help="Comma seperated list of site equivilances to apply."
    )

    args = parser.parse_args()

    with open(args.pin_assignments) as f:
        pin_assignments = json.load(f)

    ET.register_namespace('xi', XI_URL)
    with sqlite3.connect("file:{}?mode=ro".format(args.connection_database),
                         uri=True) as conn:

        cur = conn.cursor()
        tile_types = {}
        node_tile_map = {}
        sites = {}
        sites_in_tiles = {}

        pb_types = {}

        site_remaps = {}
        site_name_remaps = {}

        if args.site_equivilances is not None:
            for site_remap in args.site_equivilances.split(','):
                general_site, specific_site = site_remap.split('=')
                assert general_site not in site_name_remaps, general_site
                site_name_remaps[general_site] = specific_site

                cur.execute(
                    "SELECT pkey FROM site_type WHERE name = ?",
                    (general_site, )
                )
                general_site_type_pkey = cur.fetchone()[0]

                cur.execute(
                    "SELECT pkey FROM site_type WHERE name = ?",
                    (specific_site, )
                )
                specific_site_type_pkey = cur.fetchone()[0]

                site_remaps[general_site_type_pkey] = specific_site_type_pkey

                check_site_equiv(
                    conn, general_site_type_pkey, specific_site_type_pkey
                )

        site_collections_to_pb_type = {}

        for pb_type_def_string in args.pb_types:
            pb_type_name, pb_type_sites = pb_type_def_string.split('=')
            pb_type_sites = pb_type_sites.split(',')

            assert pb_type_name not in pb_types, pb_type_name
            pb_types[pb_type_name] = []

            for site in pb_type_sites:
                cur.execute(
                    "SELECT pkey FROM site_type WHERE name = ?", (site, )
                )
                result = cur.fetchone()
                assert result is not None, site
                site_type_pkey = result[0]
                pb_types[pb_type_name].append(site_type_pkey)

            pb_types[pb_type_name] = frozenset(pb_types[pb_type_name])

            assert pb_types[pb_type_name] not in site_collections_to_pb_type, (
                pb_type_name, pb_types[pb_type_name]
            )

            site_collections_to_pb_type[pb_types[pb_type_name]] = pb_type_name

        pb_types_in_tile = {}

        tiles_that_instance_pb_type = {}

        for tile_type in args.tile_types.split(','):
            cur.execute(
                "SELECT pkey FROM tile_type WHERE name = ?", (tile_type, )
            )
            tile_type_pkey = cur.fetchone()[0]
            tile_types[tile_type] = tile_type_pkey
            node_tile_map[tile_type_pkey] = expand_nodes_in_tile_type(
                conn, tile_type_pkey
            )
            sites[tile_type_pkey], sites_in_tiles[
                tile_type_pkey] = sites_in_tile_type(conn, tile_type_pkey)

            seen_sets = set()
            site_type_pkeys = frozenset(sites[tile_type_pkey].keys())
            seen_sets.add(site_type_pkeys)

            pb_types_in_tile[tile_type_pkey] = [
                site_collections_to_pb_type[site_type_pkeys]
            ]

            for site_set in yield_mapped_site_sets(site_remaps,
                                                   site_type_pkeys):
                if site_set in seen_sets:
                    continue

                pb_types_in_tile[tile_type_pkey].append(
                    site_collections_to_pb_type[site_set]
                )

            for pb_type in pb_types_in_tile[tile_type_pkey]:
                if pb_type not in tiles_that_instance_pb_type:
                    tiles_that_instance_pb_type[pb_type] = []

                tiles_that_instance_pb_type[pb_type].append(tile_type_pkey)

        tile_connections = {}

        for pb_type in tiles_that_instance_pb_type:
            tile_connections[pb_type] = create_pb_type(
                conn=conn,
                pin_assignments=pin_assignments,
                site_directory=args.site_directory,
                output_directory=args.output_directory,
                pb_type=pb_type,
                site_type_pkeys=pb_types[pb_type],
                tile_type_pkeys=tiles_that_instance_pb_type[pb_type],
                site_remaps=site_remaps,
                site_name_remaps=site_name_remaps,
                node_tile_map=node_tile_map
            )

        for tile_type in tile_types:
            tile_type_pkey = tile_types[tile_type]
            create_tile(
                conn=conn,
                tile_type=tile_type,
                tile_type_pkey=tile_type_pkey,
                tile_connections=tile_connections,
                pb_types=pb_types_in_tile[tile_type_pkey],
                output_directory=args.output_directory,
                pin_assignments=pin_assignments,
            )


if __name__ == '__main__':
    main()
