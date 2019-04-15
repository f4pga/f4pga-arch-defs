import lxml.etree as ET
import argparse

TAGS_TO_SWAP = ['fc', 'pinlocations', 'switchblock_locations']

def swap_tags(tile, pb_type):
    # Moving tags from top level pb_type to tile
    for child in pb_type:
        if child.tag in TAGS_TO_SWAP:
            pb_type.remove(child)
            tile.append(child)

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

    print(ET.tostring(arch_xml, pretty_print=True).decode('utf-8'))


if __name__ == '__main__':
    main()
