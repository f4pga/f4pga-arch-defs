#!/usr/bin/env python3
"""
This script is intended for processing an arch.xml file used in the OpenFPGA
project so that it can be used with the VPR used in SymbiFlow.
"""

import argparse
import re
import itertools
import sys

import lxml.etree as ET

# =============================================================================


def fixup_tiles(xml_arch):
    """
    This function convert non-heterogeneous tiles into heterogeneous with only
    one sub-tile. This is required to match with the syntax supported by the
    VPR version used in SymbiFlow.
    """

    # Legal attributes for a tile tag
    TILE_ATTRIB = ["name", "width", "height", "area"]
    # Legal attributes for a sub-tile tag
    SUB_TILE_ATTRIB = ["name", "capacity"]

    # Get the tiles section
    xml_tiles = xml_arch.find("tiles")
    assert xml_tiles is not None

    # List all tiles
    elements = xml_tiles.findall("tile")
    for xml_org_tile in elements:

        # Check if this one is heterogeneous, skip if so.
        if xml_org_tile.find("sub_tile"):
            continue

        # Detach the tile node
        xml_tiles.remove(xml_org_tile)

        # Make a new sub-tile node. Copy legal attributes and children
        xml_sub_tile = ET.Element("sub_tile",
            {k: v for k, v in xml_org_tile.attrib.items() if k in SUB_TILE_ATTRIB}
        )
        for element in xml_org_tile:
            xml_sub_tile.append(element)

        # Make a new tile node, copy legal attributes
        xml_new_tile = ET.Element("tile",
            {k: v for k, v in xml_org_tile.attrib.items() if k in TILE_ATTRIB}
        )

        # Attach nodes
        xml_new_tile.append(xml_sub_tile)
        xml_tiles.append(xml_new_tile)

    return xml_arch


def fixup_attributes(xml_arch):
    """
    Removes OpenFPGA-specific attributes from the arch.xml that are not
    accepted by the SymbiFlow VPR version.
    """

    # Remove all attributes from the layout section
    xml_old_layout = xml_arch.find("layout")
    assert xml_old_layout is not None

    xml_new_layout = ET.Element("layout")
    for element in xml_old_layout:
        xml_new_layout.append(element)

    xml_arch.remove(xml_old_layout)
    xml_arch.append(xml_new_layout)

    # Remove not supported attributes from "device/switch_block" elements
    xml_device = xml_arch.find("device")
    if xml_device is not None:

        # Legal switch_block tags
        SWITCH_BLOCK_TAGS = ["type", "fs"]

        # Remove illegal tags
        xml_switch_blocks = xml_device.findall("switch_block")
        for xml_old_switch_block in xml_switch_blocks:

            attrib = {k: v for k, v in xml_old_switch_block.attrib.items() \
                      if k in SWITCH_BLOCK_TAGS}

            xml_new_switch_block = ET.Element("switch_block", attrib)
            for element in xml_old_switch_block:
                xml_new_switch_block.append(element)

            xml_device.remove(xml_old_switch_block)
            xml_device.append(xml_new_switch_block)

    return xml_arch


def make_all_modes_packable(xml_arch):
    """
    Strips all attributes that disable packing for a mode
    """

    # Find the complexblocklist section
    xml_complexblocklist = xml_arch.find("complexblocklist")
    assert xml_complexblocklist is not None

    # Find all modes
    xml_modes = xml_complexblocklist.xpath("//mode")

    # Enable packing (by stripping all attributes except "name")
    for xml_mode in xml_modes:

        if xml_mode.get("disabled_in_pack", None) == "true" or \
           xml_mode.get("disable_packing", None) == "true" or \
           xml_mode.get("packable", None) == "false":

            xml_mode_new = ET.Element("mode", {"name": xml_mode.get("name")})

            for element in xml_mode:
                xml_mode_new.append(element)

            xml_parent = xml_mode.getparent()

            xml_parent.remove(xml_mode)
            xml_parent.append(xml_mode_new)

    return xml_arch

# =============================================================================


def pick_layout(xml_arch, layout_spec):
    """
    This function processes the <layout> section. It allows to pick the
    specified fixed layout and optionally change its name. This is required
    for SymbiFlow.
    """

    # Get layout names
    if "=" in layout_spec:
        layout_name, new_name = layout_spec.split("=", maxsplit=1)
    else:
        layout_name = layout_spec
        new_name = layout_name

    # Get the layout section
    xml_layout = xml_arch.find("layout")
    assert xml_layout is not None

    # Find the specified layout name
    found = False
    for element in xml_layout:

        # This one is fixed and name matches
        if element.tag == "fixed_layout" and \
           element.attrib["name"] == layout_name:

            # Copy the layout with a new name
            attrib = dict(element.attrib)
            attrib["name"] = new_name

            new_element = ET.Element("fixed_layout", attrib)
            for sub_element in element:
                new_element.append(sub_element)

            xml_layout.append(new_element)
            found = True

        # Remove the element
        xml_layout.remove(element)

    # Not found
    if not found:
        print("ERROR: Fixed layout '{}' not found".format(layout_name))
        exit(-1)

    return xml_arch

# =============================================================================


def main():

    # Parse arguments
    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter
    )

    parser.add_argument(
        "--arch-in",
        type=str,
        required=True,
        help="VPR arch.xml input"
    )
    parser.add_argument(
        "--arch-out",
        type=str,
        default=None,
        help="VPR arch.xml output"
    )
    parser.add_argument(
        "--pick-layout",
        type=str,
        default=None,
        help="Pick the given layout name. Optionally re-name it (<old_name>=<new_name>)"
    )

    args = parser.parse_args()

    # Read and parse the XML techfile
    xml_tree = ET.parse(args.arch_in, ET.XMLParser(remove_blank_text=True))
    xml_arch = xml_tree.getroot()
    assert xml_arch is not None and xml_arch.tag == "architecture"

    # Fixup tiles.
    fixup_tiles(xml_arch)

    # Fixup non-packable modes
    make_all_modes_packable(xml_arch)

    # Fixup OpenFPGA specific attributes
    fixup_attributes(xml_arch)

    # Pick layout
    if args.pick_layout:
        pick_layout(xml_arch, args.pick_layout)

    # Write the modified architecture file back
    xml_tree = ET.ElementTree(xml_arch)
    xml_tree.write(
        args.arch_out,
        pretty_print=True,
        encoding="utf-8"
    )

# =============================================================================

if __name__ == "__main__":
    main()
