#!/usr/bin/env python3
import argparse
import pickle
from collections import namedtuple

import lxml.etree as ET

from data_structs import *

from tile_import import make_top_level_model
from tile_import import make_top_level_pb_type
from tile_import import make_top_level_tile

# =============================================================================

ArchTileType = namedtuple("ArchTileType", "type is_tile is_pb_type")

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


def write_pb_types(xml_arch, pb_types, nsmap):
    """
    Generates "models" and "complexblocklist" sections.
    """

    xi_include = "{{{}}}include".format(nsmap["xi"])


def write_tiles(xml_arch, arch_tile_types, nsmap):
    """
    Generates "models", "complexblocklist" and "tiles" sections.
    """

    xi_include = "{{{}}}include".format(nsmap["xi"])

    # Tiles
    xml_cplx = xml_arch.find("tiles")
    if xml_cplx is None:
        xml_cplx = ET.SubElement(xml_arch, "tiles")

    for tile_type in arch_tile_types:
        if not tile_type.is_tile:
            continue

        tile_file = "{}.tile.xml".format(tile_type.type.lower())

        ET.SubElement(
            xml_cplx, xi_include, {
                "href": "tl-{}".format(tile_file),
            }
        )

    # Models
    xml_models = xml_arch.find("models")
    if xml_models is None:
        xml_models = ET.SubElement(xml_arch, "models")

    for tile_type in arch_tile_types:
        if not tile_type.is_pb_type:
            continue

        model_file = "{}.model.xml".format(tile_type.type.lower())

        ET.SubElement(
            xml_models, xi_include, {
                "href": "tl-{}".format(model_file),
                "xpointer": "xpointer(models/child::node())",
            }
        )

    # Complexblocklist
    xml_cplx = xml_arch.find("complexblocklist")
    if xml_cplx is None:
        xml_cplx = ET.SubElement(xml_arch, "complexblocklist")

    for tile_type in arch_tile_types:
        if not tile_type.is_pb_type:
            continue

        pb_type_file = "{}.pb_type.xml".format(tile_type.type.lower())

        ET.SubElement(
            xml_cplx, xi_include, {
                "href": "tl-{}".format(pb_type_file),
            }
        )


def write_tilegrid(xml_arch, tile_grid, loc_map, layout_name):
    """
    Generates the "layout" section of the arch XML and appends it to the
    root given.
    """

    # Remove the "layout" tag if any
    xml_layout = xml_arch.find("layout")
    if xml_layout is not None:
        xml_arch.remove(xml_layout)

    # Grid size
    xs = [loc.x for loc in tile_grid]
    ys = [loc.y for loc in tile_grid]
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
    for loc, tile in tile_grid.items():

        if tile is None:
            continue

        xml_sing = ET.SubElement(
            xml_fixed,
            "single",
            {
                "type": "TL-{}".format(tile.type.upper()),
                "x": str(loc.x),
                "y": str(loc.y),
                "priority": str(10),  # Not sure if we need this
            }
        )

        if loc in loc_map.bwd:
            phy_loc = loc_map.bwd[loc]

            xml_metadata = ET.SubElement(xml_sing, "metadata")
            xml_meta = ET.SubElement(
                xml_metadata, "meta", {
                    "name": "fasm_prefix",
                }
            )
            xml_meta.text = "X{}Y{}".format(phy_loc.x, phy_loc.y)


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

    # Initialize the arch XML if file not given
    xml_arch = ET.Element("architecture", nsmap=nsmap)
    initialize_arch(xml_arch, switches, segments)

    # Make a list of pb_type names which are pb_type only, not tile.
    pb_names = set()
    for tile, sites in vpr_equivalent_sites.items():
        pb_names |= set(sites.keys())

    # Make list of arch tile types
    arch_tile_types = []
    for tile_type in vpr_tile_types.keys():
        arch_tile_types.append(
            ArchTileType(
                type = tile_type,
                is_tile = \
                    tile_type not in pb_names,
                is_pb_type = \
                    tile_type not in vpr_equivalent_sites or \
                    tile_type in pb_names
            )
        )

    # Write tiles
    write_tiles(xml_arch, arch_tile_types, nsmap)
    # Write the tilegrid to arch
    write_tilegrid(xml_arch, vpr_tile_grid, loc_map, args.device)

    # Save the arch
    ET.ElementTree(xml_arch).write(
        args.arch_out,
        pretty_print=True,
        xml_declaration=True,
        encoding="utf-8"
    )

    # Generate tile, model and pb_type XMLs
    for arch_tile in arch_tile_types:

        # The top-level tile tag
        if arch_tile.is_tile:

            xml = make_top_level_tile(
                arch_tile.type, vpr_tile_types,
                vpr_equivalent_sites.get(arch_tile.type, None)
            )

            fname = "tl-{}.tile.xml".format(arch_tile.type.lower())
            ET.ElementTree(xml).write(fname, pretty_print=True)

        # The top-level pb_type and model
        if arch_tile.is_pb_type:

            tile_type = vpr_tile_types[arch_tile.type]

            fname = "tl-{}.pb_type.xml".format(arch_tile.type.lower())
            xml = make_top_level_pb_type(tile_type, nsmap)
            ET.ElementTree(xml).write(fname, pretty_print=True)

            fname = "tl-{}.model.xml".format(arch_tile.type.lower())
            xml = make_top_level_model(tile_type, nsmap)
            ET.ElementTree(xml).write(fname, pretty_print=True)


# =============================================================================

if __name__ == "__main__":
    main()
