#!/usr/bin/env python3
import os
import argparse
import pickle
from collections import namedtuple
from collections import OrderedDict

import lxml.etree as ET

from data_structs import *

from tile_import import make_top_level_pb_type
from tile_import import make_top_level_tile

# =============================================================================


def add_segment(xml_parent, segment):
    """
    Adds a segment
    """

    segment_type = "bidir"

    # Make XML
    xml_seg = ET.SubElement(
        xml_parent, "segment", {
            "name": segment.name,
            "length": str(segment.length),
            "freq": "1.0",
            "type": segment_type,
            "Rmetal": str(segment.r_metal),
            "Cmetal": str(segment.c_metal),
        }
    )

    if segment_type == "unidir":
        ET.SubElement(xml_seg, "mux", {"name": "generic"})

    elif segment_type == "bidir":
        ET.SubElement(xml_seg, "wire_switch", {"name": "generic"})
        ET.SubElement(xml_seg, "opin_switch", {"name": "generic"})

    else:
        assert False, segment_type

    e = ET.SubElement(xml_seg, "sb", {"type": "pattern"})
    e.text = " ".join(["1" for i in range(segment.length + 1)])
    e = ET.SubElement(xml_seg, "cb", {"type": "pattern"})
    e.text = " ".join(["1" for i in range(segment.length)])


def add_switch(xml_parent, switch):
    """
    Adds a switch
    """

    xml_switch = ET.SubElement(
        xml_parent, "switch", {
            "type": switch.type,
            "name": switch.name,
            "R": str(switch.r),
            "Cin": str(switch.c_in),
            "Cout": str(switch.c_out),
            "Tdel": str(switch.t_del),
        }
    )

    if switch.type in ["mux", "tristate"]:
        xml_switch.attrib["Cinternal"] = str(switch.c_int)


def initialize_arch(xml_arch, switches, segments):
    """
    Initializes the architecture definition from scratch.
    """

    # .................................
    # Device
    xml_device = ET.SubElement(xml_arch, "device")

    ET.SubElement(
        xml_device, "sizing", {
            "R_minW_nmos": "6000.0",
            "R_minW_pmos": "18000.0",
        }
    )

    ET.SubElement(xml_device, "area", {"grid_logic_tile_area": "15000.0"})

    xml = ET.SubElement(xml_device, "chan_width_distr")
    ET.SubElement(xml, "x", {"distr": "uniform", "peak": "1.0"})
    ET.SubElement(xml, "y", {"distr": "uniform", "peak": "1.0"})

    ET.SubElement(
        xml_device, "connection_block", {"input_switch_name": "generic"}
    )

    ET.SubElement(xml_device, "switch_block", {
        "type": "wilton",
        "fs": "3",
    })

    ET.SubElement(
        xml_device, "default_fc", {
            "in_type": "frac",
            "in_val": "1.0",
            "out_type": "frac",
            "out_val": "1.0",
        }
    )

    # .................................
    # Switchlist
    xml_switchlist = ET.SubElement(xml_arch, "switchlist")
    got_generic_switch = False

    for switch in switches:
        add_switch(xml_switchlist, switch)

        # Check for the generic switch
        if switch.name == "generic":
            got_generic_switch = True

    # No generic switch
    assert got_generic_switch

    # .................................
    # Segmentlist
    xml_seglist = ET.SubElement(xml_arch, "segmentlist")

    for segment in segments:
        add_segment(xml_seglist, segment)


def write_tiles(xml_arch, arch_tile_types, tile_types, equivalent_sites):
    """
    Generates the "tiles" section of the architecture file
    """

    # The "tiles" section
    xml_tiles = xml_arch.find("tiles")
    if xml_tiles is None:
        xml_tiles = ET.SubElement(xml_arch, "tiles")

    # Add tiles
    for tile_type, sub_tiles in arch_tile_types.items():

        xml = make_top_level_tile(
            tile_type, sub_tiles,
            tile_types,
            equivalent_sites
        )

        xml_tiles.append(xml)


def write_pb_types(xml_arch, arch_pb_types, tile_types, nsmap):
    """
    Generates the "complexblocklist" section.
    """

    # Complexblocklist
    xml_cplx = xml_arch.find("complexblocklist")
    if xml_cplx is None:
        xml_cplx = ET.SubElement(xml_arch, "complexblocklist")

    # Add pb_types
    for pb_type in arch_pb_types:

        xml = make_top_level_pb_type(tile_types[pb_type], nsmap)
        xml_cplx.append(xml)


def write_models(xml_arch, arch_models, nsmap):
    """
    Generates the "models" section.
    """

    # Models
    xml_models = xml_arch.find("models")
    if xml_models is None:
        xml_models = ET.SubElement(xml_arch, "models")

    # Include cell models
    xi_include = "{{{}}}include".format(nsmap["xi"])
    for model in arch_models:
        name = model.lower()

        # Be smart. Check if there is a file for that cell in the current
        # directory. If not then use the one from "primitives" path
        model_file = "./{}.model.xml".format(name)
        if not os.path.isfile(model_file):
            model_file = "../../primitives/{}/{}.model.xml".format(name, name)

        ET.SubElement(
            xml_models, xi_include, {
                "href": model_file,
                "xpointer": "xpointer(models/child::node())",
            }
        )


def write_tilegrid(xml_arch, arch_tile_grid, loc_map, layout_name):
    """
    Generates the "layout" section of the arch XML and appends it to the
    root given.
    """

    # Remove the "layout" tag if any
    xml_layout = xml_arch.find("layout")
    if xml_layout is not None:
        xml_arch.remove(xml_layout)

    # Grid size
    xs = [flat_loc[0] for flat_loc in arch_tile_grid]
    ys = [flat_loc[1] for flat_loc in arch_tile_grid]
    w = max(xs) + 1
    h = max(ys) + 1

    # Fixed layout
    xml_layout = ET.SubElement(xml_arch, "layout")
    xml_fixed = ET.SubElement(
        xml_layout, "fixed_layout", {
            "name": layout_name,
            "width": str(w),
            "height": str(h),
        }
    )

    # Individual tiles
    for flat_loc, tile in arch_tile_grid.items():

        if tile is None:
            continue

        # Unpack
        tile_type, capacity = tile

        # Single tile
        xml_sing = ET.SubElement(
            xml_fixed,
            "single",
            {
                "type": "TL-{}".format(tile_type.upper()),
                "x": str(flat_loc[0]),
                "y": str(flat_loc[1]),
                "priority": str(10),  # Not sure if we need this
            }
        )

        # Gather metadata
        metadata = []
        for i in range(capacity):
            loc = Loc(x=flat_loc[0], y=flat_loc[1], z=i)

            if loc in loc_map.bwd:
                phy_loc = loc_map.bwd[loc]
                metadata.append("X{}Y{}".format(phy_loc.x, phy_loc.y))

        # Emit metadata if any
        if len(metadata):
            xml_metadata = ET.SubElement(xml_sing, "metadata")
            xml_meta = ET.SubElement(
                xml_metadata, "meta", {
                    "name": "fasm_prefix",
                }
            )
            xml_meta.text = " ".join(metadata)


# =============================================================================


def main():

    # Parse arguments
    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter
    )

    parser.add_argument(
        "--vpr-db", type=str, required=True, help="VPR database file"
    )
    parser.add_argument(
        "--arch-out",
        type=str,
        default="arch.xml",
        help="Output arch XML file (def. arch.xml)"
    )
    parser.add_argument(
        "--device",
        type=str,
        default="quicklogic",
        help="Device name for the architecture"
    )

    args = parser.parse_args()

    xi_url = "http://www.w3.org/2001/XInclude"
    ET.register_namespace("xi", xi_url)
    nsmap = {"xi": xi_url}

    # Load data from the database
    with open(args.vpr_db, "rb") as fp:
        db = pickle.load(fp)

        cells_library = db["cells_library"]
        loc_map = db["loc_map"]
        vpr_tile_types = db["vpr_tile_types"]
        vpr_tile_grid = db["vpr_tile_grid"]
        vpr_equivalent_sites = db["vpr_equivalent_sites"]
        segments = db["segments"]
        switches = db["switches"]

    # TODO: Do not support equivalent sites for tiles now
    assert len(vpr_equivalent_sites) == 0, "Equivalent sites not supported yet!"

    # Flatten the VPR tilegrid
    flat_tile_grid = dict()
    for vpr_loc, tile in vpr_tile_grid.items():

        flat_loc = (vpr_loc.x, vpr_loc.y)
        if flat_loc not in flat_tile_grid:
            flat_tile_grid[flat_loc] = {}

        if tile is not None:
            flat_tile_grid[flat_loc][vpr_loc.z] = tile.type

    # Create the arch tile grid and arch tile types
    arch_tile_grid  = dict()
    arch_tile_types = dict()
    arch_pb_types   = set()
    arch_models     = set()

    for flat_loc, tiles in flat_tile_grid.items():

        if len(tiles):

            # Group identical sub-tiles together, maintain their order
            sub_tiles = OrderedDict()
            for z, tile in tiles.items():
                if tile not in sub_tiles:
                    sub_tiles[tile] = 0
                sub_tiles[tile] += 1
            
            # TODO: Make arch tile type name
            tile_type = tiles[0]

            # Create the tile type with sub tile types for the arch
            arch_tile_types[tile_type] = sub_tiles

            # Add each sub-tile to top-level pb_type list
            for tile in sub_tiles:
                arch_pb_types.add(tile)

            # Add each cell of a sub-tile to the model list
            for tile in sub_tiles:
                for cell_type in vpr_tile_types[tile].cells.keys():
                    arch_models.add(cell_type)

            # Add the arch tile type to the arch tile grid
            arch_tile_grid[flat_loc] = (tile_type, len(tiles),)

        else:

            # Add an empty location
            arch_tile_grid[flat_loc] = None

    # Initialize the arch XML if file not given
    xml_arch = ET.Element("architecture", nsmap=nsmap)
    initialize_arch(xml_arch, switches, segments)

    # Add tiles
    write_tiles(xml_arch, arch_tile_types, vpr_tile_types, vpr_equivalent_sites)
    # Add pb_types
    write_pb_types(xml_arch, arch_pb_types, vpr_tile_types, nsmap)
    # Add models
    write_models(xml_arch, arch_models, nsmap)

    # Write the tilegrid to arch
    write_tilegrid(xml_arch, arch_tile_grid, loc_map, args.device)

    # Save the arch
    ET.ElementTree(xml_arch).write(
        args.arch_out,
        pretty_print=True,
        xml_declaration=True,
        encoding="utf-8"
    )


# =============================================================================

if __name__ == "__main__":
    main()
