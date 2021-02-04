#!/usr/bin/env python3
"""
This script loads VPR architecture definition and flattens all layouts defined
there so that they only consist of <single> tags. Tiles of the flattened
layouts can have individual metadata (FASM prefixes) assigned.

The FASM prefix pattern is provided with the --fasm_prefix parameter. The
pattern string may contain tag references that are replaced with tile specific
data. Tags have to be provided in curly brackets. The recoginzed tags are:

 - 'tile'     : tile type name
 - 'sub_tile' : Sub-tile type name
 - 'x'        : X locatin in the VPR grid
 - 'y'        : X locatin in the VPR grid
 - 'z'        : Z locatin in the VPR grid (cumulated sub-tile index)
 - 'i'        : Sub-tile index

For conveniance the pattern string may also use simple math. expressions to eg.
transform the grid coordinates. For an expression to be evaluated one has to
be given in round brackets.

An example of a pattern that uses tags:

 "TILE_{tile_name}_X{x}Y{y}"

An example of a pattern that transforms the X coordinate:

 "{tile_name}_X({x}+10)Y{y}"

"""

import argparse
import re
import itertools
import sys

import lxml.etree as ET

# =============================================================================

# Empty tile name
EMPTY = "EMPTY"

# =============================================================================


class GridLocSpec:
    """
    Grid location specification construct that corresponds to VPR grid location tags:
    https://docs.verilogtorouting.org/en/latest/arch/reference/#grid-location-tags
    """

    PARAMS = (
        ("x", None),
        ("y", None),
        ("startx", "0"),
        ("starty", "0"),
        ("endx", "W-1"),
        ("endy", "H-1"),
        ("incrx", "w"),
        ("incry", "h"),
    )

    def __init__(self, xml_elem, tile_types):

        # Get the grid dimensions
        xml_parent = xml_elem.getparent()
        grid_w = int(xml_parent.attrib["width"])
        grid_h = int(xml_parent.attrib["height"])

        # Common fields
        self.type = xml_elem.tag
        self.tile = xml_elem.attrib["type"]
        self.priority = int(xml_elem.attrib["priority"])
        self.xml_metadata = None

        # Get the tile size
        self.tile_w, self.tile_h = tile_types[self.tile][0:2]

        # Optional fields but common to many constructs
        globs  = {"W": grid_w, "H": grid_h, "w": self.tile_w, "h": self.tile_h}
        params = {}
        for param, default in self.PARAMS:
            s = xml_elem.attrib.get(param, default)
            if s is not None:            
                params[param] = int(eval(s, {'__builtins__':None}, globs))

        # "fill"
        if xml_elem.tag == "fill":
            self.locs = set(
                [loc for loc in itertools.product(
                    range(0, grid_w, self.tile_w),
                    range(0, grid_h, self.tile_h)
                )]
            )

        # "corners"
        elif xml_elem.tag == "corners":
            self.locs = set([
                (0, 0,),
                (grid_w - self.tile_w, 0),
                (0, grid_h - self.tile_h),
                (grid_w - self.tile_w, grid_h - self.tile_h)
            ])

        # "perimeter"
        elif xml_elem.tag == "perimeter":
            self.locs = set()

            for x in range(0, grid_w, self.tile_w):
                self.locs.add((x, 0,))
                self.locs.add((x, grid_h - self.tile_h,))

            for y in range(self.tile_h, grid_h - self.tile_h, self.tile_h):
                self.locs.add((0, y))
                self.locs.add((grid_w - self.tile_w, y))

        # "region"
        elif xml_elem.tag == "region":

            # TODO: Support repeatx and repeaty
            assert "repeatx" not in xml_elem.attrib, "'repeatx' not supported"
            assert "repeaty" not in xml_elem.attrib, "'repeaty' not supported"

            self.locs = set(
                [(x, y,) for x, y in itertools.product(
                    range(params["startx"], params["endx"] + 1, params["incrx"]),
                    range(params["starty"], params["endy"] + 1, params["incry"])
                )]
            )

        # "row"
        elif xml_elem.tag == "row":

            # TODO: Support incry
            assert "incry" not in xml_elem.attrib, "'incry' not supported"

            self.locs = set([
                (x, params["starty"],) for x in range(params["startx"], grid_w)
            ])

        # "col"
        elif xml_elem.tag == "col":

            # TODO: Support incrx
            assert "incrx" not in xml_elem.attrib, "'incrx' not supported"

            self.locs = set([
                (params["startx"], y) for y in range(params["starty"], grid_h)
            ])

        # "single"
        elif xml_elem.tag == "single":
            self.locs = set(((params["x"], params["y"],),))

            # For "single" store its original metadata
            self.xml_metadata = xml_elem.find("metadata")

        else:
            assert False, "Unknown grid location spec '{}'".format(xml_elem.tag)

# =============================================================================


def dump_tile_grid(grid, file=sys.stdout):
    """
    A debugging function. Dumps the tile (block) grid as ASCII text.
    """

    print("Tile grid:", file=file)
    xmax = max([loc[0] for loc in grid])
    ymax = max([loc[1] for loc in grid])
    for y in range(ymax + 1):
        l = " {:>2}: ".format(y)
        for x in range(xmax + 1):
            loc = (x, y,)
            if loc not in grid:
                l += '.'
            else:
                tile_type = grid[loc]

                if tile_type == EMPTY:
                    l += '.'
                else:
                    l += tile_type[0].upper()
        print(l, file=file)


def assemble_grid(gridspec_list):
    """
    Assembles the tilegrid from multipe GridLocSpec objects
    """

    # Sort by priority
    gridspec_list = sorted(gridspec_list, key=lambda item: item.priority)

    # Assemble the grid
    grid = {}
    for gridspec in gridspec_list:
        for loc in gridspec.locs:

            # Clear the tile area in case it has width and/or height > 1
            if gridspec.tile_w > 1 or gridspec.tile_h > 1:
                for x, y in itertools.product(
                    range(gridspec.tile_w),
                    range(gridspec.tile_h)):

                    l = (loc[0] + x, loc[1] + y)
                    grid[l] = EMPTY

            # Base tile location
            grid[loc] = gridspec.tile

    # Dump the grid
    dump_tile_grid(grid, sys.stderr)

    return grid


def process_fixed_layout(xml_layout, tile_types, sub_tile_prefix, args):
    """
    Processes a fixed layout. Converts it to a layout consisting only of
    "single" tiles.
    """

    print("Processing fixed layout '{}' ...".format(xml_layout.attrib["name"]),
        file=sys.stderr)

    # Decode grid location specifications
    grid_spec = []
    for xml_elem in xml_layout:
        if xml_elem.tag is not ET.Comment:
            grid_spec.append(GridLocSpec(xml_elem, tile_types))

    # Assemble the tile grid
    grid = assemble_grid(grid_spec)

    # "prefix only", "no prefix" lists
    if args.prefix_only is not None:
        prefix_only = set(args.prefix_only.split(","))
    else:
        prefix_only = set(tile_types.keys())

    if args.no_prefix is not None:
        no_prefix = set(args.no_prefix.split(","))
    else:
        no_prefix = set()

    # Math equation evaluation function
    def math_eval(match):
        return str(eval(match.group(1), {'__builtins__':None}, {}))

    # Write layout
    xml_layout_new = ET.Element("fixed_layout", attrib=xml_layout.attrib)
    keys = sorted(list(grid.keys()))
    for loc in keys:
        tile_type = grid[loc]

        # Skip EMPTY tiles, in VPR tiles are empty by default
        if tile_type == EMPTY:
            continue

        # Create a new "single" tag
        xml_single = ET.Element("single", attrib = {
            "type": tile_type,
            "x": str(loc[0]),
            "y": str(loc[1]),
            "priority": "10" # FIXME: Arbitrary
        })        

        # Append metadata
        if args.fasm_prefix is not None:
            if tile_type in prefix_only and tile_type not in no_prefix:

                sub_tiles = tile_types[tile_type][2]
                fasm_prefixes = []

                # Make prefix for each sub-tile
                z = 0
                for sub_tile_type, capacity in sub_tiles:
                    for i in range(capacity):

                        # Render the FASM prefix template
                        tags = {
                            "tile": tile_type,
                            "sub_tile": sub_tile_type,
                            "x": str(loc[0]),
                            "y": str(loc[1]),
                            "z": str(z),
                            "i": str(i)
                        }

                        fasm_prefix = args.fasm_prefix.format(**tags)

                        # Check if we need to add another prefix for the
                        # sub-tile
                        if sub_tile_type in sub_tile_prefix:
                            fasm_prefix += "."
                            fasm_prefix += sub_tile_prefix[sub_tile_type].format(**tags)

                        # Evaluate equations
                        fasm_prefix = re.sub(r"\[([0-9+\-*/%]+)\]",
                                             math_eval, fasm_prefix)

                        fasm_prefixes.append(fasm_prefix)
                        z = z + 1

                # Create and append the XML tag
                xml_metadata = ET.Element("metadata")
                xml_meta = ET.Element("meta", attrib={"name": "fasm_prefix"})
                xml_meta.text = " ".join(fasm_prefixes)
                xml_metadata.append(xml_meta)
                xml_single.append(xml_metadata)

        xml_layout_new.append(xml_single)

    return xml_layout_new


def process_layouts(xml_layout, tile_types, args):
    """
    Processes grid layouts
    """

    # Parse format strings for sub-tile prefixes
    sub_tile_prefix = {}
    for spec in args.sub_tile_prefix:
        parts = spec.strip().split("=")
        assert len(parts) == 2, spec
        sub_tile_prefix[parts[0]] = parts[1]

    # Look for "fixed_layout" and process them
    for xml_elem in list(xml_layout):
        if xml_elem.tag == "fixed_layout":            

            xml_layout_new = process_fixed_layout(
                xml_elem, tile_types, sub_tile_prefix, args)

            xml_layout.remove(xml_elem)
            xml_layout.append(xml_layout_new)

# =============================================================================


def parse_tiles(xml_tiles):
    """
    Read tile sizes (width and height) and sub-tile counts
    """

    tile_types = {}

    # Process all "tile" tags
    for xml_tile in xml_tiles.findall("tile"):
        name   = xml_tile.attrib["name"]
        width  = int(xml_tile.attrib.get("width", "1"))
        height = int(xml_tile.attrib.get("height", "1"))

        # Process sub-tile tags
        sub_tiles = []
        for xml_sub_tile in xml_tile.findall("sub_tile"):
            sub_name  = xml_sub_tile.attrib["name"]
            sub_count = int(xml_sub_tile.get("capacity", "1"))
            sub_tiles.append((sub_name, sub_count,))

        # No sub-tiles, assume that the tile is not heterogeneous
        if not sub_tiles:
            count = int(xml_tile.get("capacity", "1"))
            sub_tiles = [(name, count,)]

        tile_types[name] = (width, height, tuple(sub_tiles),)

    # Add entry for the EMPTY tile
    tile_types[EMPTY] = (1, 1, (EMPTY, 1,),)

    return tile_types

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
        "--fasm_prefix",
        type=str,
        default=None,
        help="A template string for FASM prefix (def. None)"
    )
    parser.add_argument(
        "--sub-tile-prefix",
        type=str,
        default=[],
        nargs="+",
        help="Template strings for sub-tile FASM prefixes (<sub_tile>=<prefix_fmt>) (def. None) "
    )
    parser.add_argument(
        "--prefix-only",
        type=str,
        default=None,
        help="A comma separated list of tile types to be prefixed"
    )
    parser.add_argument(
        "--no-prefix",
        type=str,
        default=None,
        help="A comma separated list of tile types NOT to be prefixed"
    )

    args = parser.parse_args()

    # Read and parse the XML techfile
    xml_tree = ET.parse(args.arch_in, ET.XMLParser(remove_blank_text=True))
    xml_arch = xml_tree.getroot()
    assert xml_arch is not None and xml_arch.tag == "architecture"

    # Get tiles
    xml_tiles = xml_arch.find("tiles")
    assert xml_tiles is not None

    # Get tile sizes
    tile_types = parse_tiles(xml_tiles)

    # Get layout
    xml_layout = xml_arch.find("layout")
    assert xml_layout is not None

    # Process the layout
    process_layouts(xml_layout, tile_types, args)

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

