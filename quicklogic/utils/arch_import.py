#!/usr/bin/env python3
import argparse

#import xml.etree.ElementTree as ET
import lxml.etree as ET

from data_structs import *
from data_import import import_data

# =============================================================================

def process_tilegrid(tile_types, tile_grid):
    """
    Processes the tilegrid. May add/remove tiles. Returns a new one.
    """

    new_tile_grid = {}
    for loc, tile in tile_grid.items():
        
        # FIXME: For now keep only tile that contains only one LOGIC cell inside
        tile_type = tile_types[tile.type]
        if len(tile_type.cells) == 1 and tile_type.cells[0].type == "LOGIC":
            new_tile_grid[loc] = tile

    return new_tile_grid

# =============================================================================


def initialize_arch(xml_arch):
    """
    Initializes the architecture definition from scratch.
    """

    switch_name = "sw"

    # .................................
    # Device
    xml_device = ET.SubElement(xml_arch, "device")

    ET.SubElement(xml_device, "sizing", {
        "R_minW_nmos": "6000.0",
        "R_minW_pmos": "18000.0",
    })

    ET.SubElement(xml_device, "area", {
        "grid_logic_tile_area": "15000.0"
    })

    xml = ET.SubElement(xml_device, "chan_width_distr")
    ET.SubElement(xml, "x", {"distr": "uniform", "peak": "1.0"})
    ET.SubElement(xml, "y", {"distr": "uniform", "peak": "1.0"})

    ET.SubElement(xml_device, "connection_block", {
        "input_switch_name": switch_name
    })

    ET.SubElement(xml_device, "switch_block", {
        "type": "wilton",
        "fs": "3",
    })

    ET.SubElement(xml_device, "default_fc", {
        "in_type": "frac",
        "in_val": "1.0",
        "out_type": "frac",
        "out_val": "1.0",
    })

    # .................................
    # Switchlist
    xml_switchlist = ET.SubElement(xml_arch, "switchlist")

    ET.SubElement(xml_switchlist, "switch", {
        "type": "short",
        "name": switch_name,
        "R": "0",
        "Cin": "0",
        "Cout": "0",
        "Tdel": "0"
    })

    # .................................
    # Segmentlist
    xml_seglist = ET.SubElement(xml_arch, "segmentlist")    


def write_tiles(xml_arch, tile_types, nsmap):
    """
    Generates "models" and "complexblocklist" sections.
    """

    xi_include = "{{{}}}include".format(nsmap["xi"])

    # Models
    xml_models = xml_arch.find("models")
    if xml_models is None:
        xml_models = ET.SubElement(xml_arch, "models")

    for tile_type in tile_types.values():
        model_file = "{}.model.xml".format(tile_type.type.lower())

        ET.SubElement(xml_models, xi_include, {
            "href": model_file,
            "xpointer": "xpointer(models/child::node())",
        })

    # Complexblocklist
    xml_cplx = xml_arch.find("complexblocklist")
    if xml_cplx is None:
        xml_cplx = ET.SubElement(xml_arch, "complexblocklist")

    for tile_type in tile_types.values():
        pb_type_file = "{}.pb_type.xml".format(tile_type.type.lower())

        ET.SubElement(xml_cplx, xi_include, {
            "href": pb_type_file,
        })


def write_tilegrid(xml_arch, tile_grid, layout_name):
    """
    Generates the "layout" section of the arch XML and appends it to the
    root given.
    """

    # Remove the "layout" tag if any
    xml_layout = xml_arch.find("layout")
    if xml_layout is not None:
        xml_arch.remove(xml_layout)

    # Grid size
    # FIXME: Shouldn't the "size" be just max(xs), max(ys) in VPR ????
    xs = [loc.x for loc in tile_grid]
    ys = [loc.y for loc in tile_grid]
    w  = max(xs) - min(xs) + 1
    h  = max(ys) - min(ys) + 1

    # Fixed layout
    xml_layout = ET.SubElement(xml_arch, "layout")
    xml_fixed  = ET.SubElement(xml_arch, "fixed", {
        "name": layout_name,
        "width": str(w),
        "height": str(h),
    })

    # Individual tiles
    for loc, tile in tile_grid.items():

        # FIXME: Assign correct fasm prefixes
        fasm_prefix = "TILE_X{}Y{}".format(loc.x, loc.y)

        xml_sing = ET.SubElement(xml_fixed, "single", {
            "type": tile.type,
            "x": str(loc.x),
            "y": str(loc.y),
            "priority": str(10), # Not sure if we need this
        })

        xml_metadata = ET.SubElement(xml_sing, "metadata")
        xml_meta = ET.SubElement(xml_metadata, "meta", {
            "name": "fasm_prefix",
        })
        xml_meta.text = fasm_prefix

# =============================================================================


def main():
    
    # Parse arguments
    parser = argparse.ArgumentParser(description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter)

    parser.add_argument(
        "--techfile",
        type=str,
        required=True,
        help="Quicklogic 'TechFile' XML file"
    )
    parser.add_argument(
        "--arch-in",
        type=str,
        default=None,
        help="Input arch XML file (for patching, optional)"
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

    # Read the input arch XML file if given
    if args.arch_in:
        xml_tree = ET.parse(args.arch_in)
        xml_arch = xml_tree.getroot()

    # Initialize the arch XML if file not given
    else:
        xml_arch = ET.Element("architecture", nsmap=nsmap)
        initialize_arch(xml_arch)

    # Read and parse the XML techfile
    xml_tree = ET.parse(args.techfile)
    xml_techfile = xml_tree.getroot()

    # Load data from the techfile
    cells_library, tile_types, tile_grid, switchboxes, switchbox_grid, = import_data(xml_techfile)

    # Process the tilegrid
    vpr_tile_grid = process_tilegrid(tile_types, tile_grid)

    # Get tile types present in the grid
    vpr_tile_types = set([t.type for t in vpr_tile_grid.values()])
    vpr_tile_types = {k: v for k, v in tile_types.items() if k in vpr_tile_types}

    # Write tiles
    write_tiles(xml_arch, vpr_tile_types, nsmap)
    # Write the tilegrid to arch
    write_tilegrid(xml_arch, vpr_tile_grid, args.device)

    # Save the arch
    ET.ElementTree(xml_arch).write(args.arch_out, pretty_print=True, xml_declaration=True, encoding="utf-8")

# =============================================================================

if __name__ == "__main__":
    main()
