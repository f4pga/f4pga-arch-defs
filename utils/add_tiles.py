import lxml.etree as ET
import argparse

TAGS_TO_SWAP = ['fc', 'pinlocations', 'switchblock_locations']
EQUIVALENT_TILES = {
            'BLK_TI-CLBLL_R': ['BLK_TI-CLBLL_L', 'BLK_TI-CLBLM_L', 'BLK_TI-CLBLM_R'],
            'BLK_TI-CLBLL_L': ['BLK_TI-CLBLL_R', 'BLK_TI-CLBLM_L', 'BLK_TI-CLBLM_R'],
            'BLK_TI-CLBLM_R': ['BLK_TI-CLBLM_L'],
            'BLK_TI-CLBLM_L': ['BLK_TI-CLBLM_R']
        }

CLBS_PORTS = {
        'CLBLL_L': ['CLBLM_L', 'CLBLL_L'],
        'CLBLL_LL': ['CLBLM_M', 'CLBLL_LL'],
        'CLBLM_L': ['CLBLM_L'],
        'CLBLM_M': ['CLBLM_M']
        }

PORTS = ['input', 'output', 'clock']

def swap_tags(tile, pb_type):
    # Moving tags from top level pb_type to tile
    for child in pb_type:
        if child.tag in TAGS_TO_SWAP:
            pb_type.remove(child)
            tile.append(child)


def get_ports_names(pb_type):
    for child in pb_type:
        if child.tag in PORTS:
            yield child.get('name')


def get_equivalent_port_name(pin_name, port_name, eq_ports):
    for port, eq_port_name, pin in eq_ports:
        if pin == pin_name and eq_port_name in CLBS_PORTS[port_name]:
            return port

    return None


def add_equivalent_tiles_mapping(mode, pb_type, eq_pb_type):
    ports = []
    eq_ports = []

    for port in get_ports_names(pb_type):
        split = port.split('_')
        pin = split[-1]
        port_name = "_".join(split[:-1])
        ports.append((port, port_name, pin))

    for eq_port in get_ports_names(eq_pb_type):
        split = eq_port.split('_')
        pin = split[-1]
        port_name = "_".join(split[:-1])
        eq_ports.append((eq_port, port_name, pin))

    assert len(ports) <= len(eq_ports), "Number of ports of original type are more than the equivalent ones."

    for port, port_name, pin in ports:
        eq_port = get_equivalent_port_name(pin, port_name, eq_ports)
        assert eq_port is not None, "Could not find port."

        port_map = ET.SubElement(mode, 'map')
        port_map.set('from', port)
        port_map.set('to', eq_port)


def get_eq_pb_type(tile, root_element):
    for pb_type in root_element.iter('pb_type'):
        if pb_type.get('name') == tile:
            return pb_type
    return None


def main():
    parser = argparse.ArgumentParser(
        description="Moves top level pb_types to tiles tag."
    )
    parser.add_argument(
        '--input_arch_xml',
        required=True,
        help="Input arch.xml to specialized."
    )

    args = parser.parse_args()

    arch_xml = ET.ElementTree()
    root_element = arch_xml.parse(args.input_arch_xml)

    tiles = ET.SubElement(root_element, 'tiles')

    top_pb_types = []
    for pb_type in root_element.iter('pb_type'):
        if pb_type.getparent().tag == 'complexblocklist':
            top_pb_types.append(pb_type)

    for pb_type in top_pb_types:
        tile = ET.SubElement(tiles, 'tile')
        attrs = pb_type.attrib

        for attr in attrs:
            tile.set(attr, pb_type.get(attr))

        swap_tags(tile, pb_type)

        tile_name = tile.get('name')

        if tile_name not in EQUIVALENT_TILES.keys():
            continue

        equivalent_tag = ET.SubElement(tile, 'equivalent_tiles')

        eq_tiles = EQUIVALENT_TILES[tile_name]
        for eq_tile in eq_tiles:
            eq_pb_type = get_eq_pb_type(eq_tile, root_element)
            assert eq_pb_type is not None, "No pb_type found"

            mode = ET.SubElement(equivalent_tag, 'mode')
            mode.set('name', eq_tile)
            add_equivalent_tiles_mapping(mode, pb_type, eq_pb_type)


    print(ET.tostring(arch_xml, pretty_print=True).decode('utf-8'))


if __name__ == '__main__':
    main()
