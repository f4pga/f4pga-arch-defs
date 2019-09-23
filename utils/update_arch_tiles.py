#!/usr/bin/env python

import argparse
import sys
import copy

from lxml import etree as ET


def add_tile_tags(arch):
    """
    This script is intended to modify the architecture description file to be compliant with
    the new format.

    It moves the top level pb_types attributes and tags to the tiles high-level tag.

    BEFORE:
    <complexblocklist>
        <pb_type name="BRAM" area="2" height="4" width="1" capacity="1">
            <inputs ... />
            <outputs ... />
            <interconnect ... />
            <fc ... />
            <pinlocations ... />
            <switchblock_locations ... />
        </pb_type>
    </complexblocklist>

    AFTER:
    <tiles>
        <tile name="BRAM" area="2" height="4" width="1" capacity="1">
            <inputs ... />
            <outputs ... />
            <fc ... />
            <pinlocations ... />
            <switchblock_locations ... />
            <equivalent_sites>
                <site pb_type="BRAM"/>
            </equivalent_sites>
        </tile>
    </tiles>
    <complexblocklist
        <pb_type name="BRAM">
            <inputs ... />
            <outputs ... />
            <interconnect ... />
        </pb_type>
    </complexblocklist>

    """

    TAGS_TO_SWAP = ['fc', 'pinlocations', 'switchblock_locations']
    TAGS_TO_COPY = ['input', 'output', 'clock']
    ATTR_TO_SWAP = ['area', 'height', 'width', 'capacity']

    def swap_tags(tile, pb_type):
        # Moving tags from top level pb_type to tile
        for child in pb_type:
            if child.tag in TAGS_TO_SWAP:
                pb_type.remove(child)
                tile.append(child)
            if child.tag in TAGS_TO_COPY:
                child_copy = copy.deepcopy(child)
                tile.append(child_copy)

    if arch.findall('./tiles'):
        return False

    models = arch.find('./models')

    tiles = ET.Element('tiles')
    models.addnext(tiles)

    top_pb_types = []
    for pb_type in arch.iter('pb_type'):
        if pb_type.getparent().tag == 'complexblocklist':
            top_pb_types.append(pb_type)

    for pb_type in top_pb_types:
        tile = ET.SubElement(tiles, 'tile')
        attrs = pb_type.attrib

        for attr in attrs:
            tile.set(attr, pb_type.get(attr))

        # Remove attributes of top level pb_types only
        for attr in ATTR_TO_SWAP:
            pb_type.attrib.pop(attr, None)

        equivalent_sites = ET.Element("equivalent_sites")
        site = ET.Element("site")
        site.set("pb_type", attrs['name'])

        equivalent_sites.append(site)
        tile.append(equivalent_sites)

        swap_tags(tile, pb_type)

    return True


def main():
    parser = argparse.ArgumentParser()

    parser.add_argument("--in_xml", required=True, help="xml_file to update")
    parser.add_argument("--out_xml", required=True, help="updated xml_file")

    args = parser.parse_args()

    parser = ET.XMLParser(remove_blank_text=True)
    root = ET.parse(args.in_xml, parser)

    root_tags = root.findall(".")
    assert len(root_tags) == 1
    arch = root_tags[0]

    if arch.tag != "architecture":
        print("Warning! Not an architecture file, exiting...")
        sys.exit(0)

    modified = False
    result = add_tile_tags(arch)
    if result:
        modified = True

    if modified:
        with open(args.out_xml, "wb") as f:
            root.write(f, pretty_print=True)


if __name__ == "__main__":
    main()
