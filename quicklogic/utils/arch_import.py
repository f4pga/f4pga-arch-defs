#!/usr/bin/env python3
import argparse
import pickle

import lxml.etree as ET

from data_structs import *

# =============================================================================

def add_synthetic_cell_and_tile_types(tile_types, cells_library):

    # The synthetic IO PAD cell.
    cell_type = CellType(
        type = "SYN_PAD",
        pins = (
            Pin(name="I", is_clock=False, direction=PinDirection.OUTPUT),
            Pin(name="O", is_clock=False, direction=PinDirection.INPUT),
        )
    )
    cells_library[cell_type.type] = cell_type

    # The synthetic IO tile.
    tile_type = TileType("SYN_IO", {"SYN_PAD": 1})
    tile_type.make_pins(cells_library)
    tile_types[tile_type.type] = tile_type


def process_tilegrid(tile_types, tile_grid):
    """
    Processes the tilegrid. May add/remove tiles. Returns a new one.
    """

    # Generate the VPR tile grid
    new_tile_grid = {}
    for loc, tile in tile_grid.items():

        # FIXME: Import only the top-left corner
        if loc.x > 7 or loc.y > 8:
            continue       

        tile_type = tile_types[tile.type]

        # Insert synthetic tiles in place of tiles that contain a BIDIR cell.
        if "BIDIR" in tile_type.type:
            new_tile_grid[loc] = Tile(
                type = "SYN_IO",
                name = tile.name
            )
            continue
 
        # FIXME: For now keep only tile that contains only one LOGIC cell inside
        if len(tile_type.cells) == 1 and list(tile_type.cells.keys())[0] == "LOGIC":
            new_tile_grid[loc] = tile

    return new_tile_grid

# =============================================================================


def initialize_arch(xml_arch):
    """
    Initializes the architecture definition from scratch.
    """

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
        "input_switch_name": "mux"
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
        "name": "short",
        "R": "0",
        "Cin": "0",
        "Cout": "0",
        "Tdel": "0"
    })

    ET.SubElement(xml_switchlist, "switch", {
        "type": "mux",
        "name": "mux",
        "R": "0",
        "Cin": "0",
        "Cout": "0",
        "Tdel": "0"
    })

    # .................................
    # Segmentlist
    xml_seglist = ET.SubElement(xml_arch, "segmentlist")    

    def add_segment(name, length):
        """
        Adds a segment
        """

        xml_seg = ET.SubElement(xml_seglist, "segment", {
            "name": name,
            "length": str(length),
            "freq": "1.0",
            "type": "unidir",
            "Rmetal": "100",
            "Cmetal": "22e-15",
        })

        ET.SubElement(xml_seg, "mux", {"name": "mux"})

        e = ET.SubElement(xml_seg, "sb", {"type": "pattern"})
        e.text = " ".join(["1" for i in range(length+1)])
        e = ET.SubElement(xml_seg, "cb", {"type": "pattern"})
        e.text = " ".join(["1" for i in range(length)])

    add_segment("dummy", 2)


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

    # Tiles
    xml_cplx = xml_arch.find("tiles")
    if xml_cplx is None:
        xml_cplx = ET.SubElement(xml_arch, "tiles")

    for tile_type in tile_types.values():
        pb_type_file = "{}.tile.xml".format(tile_type.type.lower())

        ET.SubElement(xml_cplx, xi_include, {
            "href": pb_type_file,
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
            "type": "TL-{}".format(tile.type),
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
        "--db",
        type=str,
        required=True,
        help="Database file"
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

    # Load data from the database
    with open(args.db, "rb") as fp:
        db = pickle.load(fp)

        cells_library = db["cells_library"]
        tile_types    = db["tile_types"]
        phy_tile_grid = db["phy_tile_grid"]

    # DEBUG
    print("PHY cell types:")
    for t in cells_library.keys():
        print("", t)

    print("PHY Tile types:")
    for t in tile_types.keys():
        print("", t)

    # Add synthetic stuff
    add_synthetic_cell_and_tile_types(tile_types, cells_library)
    # Process the tilegrid
    vpr_tile_grid = process_tilegrid(tile_types, phy_tile_grid)

    # Get tile types present in the grid
    vpr_tile_types = set([t.type for t in vpr_tile_grid.values()])
    vpr_tile_types = {k: v for k, v in tile_types.items() if k in vpr_tile_types}

    # Write tiles
    write_tiles(xml_arch, vpr_tile_types, nsmap)
    # Write the tilegrid to arch
    write_tilegrid(xml_arch, vpr_tile_grid, args.device)

    # Save the arch
    ET.ElementTree(xml_arch).write(args.arch_out, pretty_print=True, xml_declaration=True, encoding="utf-8")

    # === MOVE ELSEWHERE ====
    from tile_import import make_top_level_pb_type
    from tile_import import make_top_level_tile

    for tile_type in vpr_tile_types.values():

        # The top-level tile tag
        fname = "{}.tile.xml".format(tile_type.type.lower())
        xml = make_top_level_tile(tile_type)
        ET.ElementTree(xml).write(fname, pretty_print=True)

        # The top-level pb_type wrapper tag
        fname = "{}.pb_type.xml".format(tile_type.type.lower())
        xml = make_top_level_pb_type(tile_type, nsmap)
        ET.ElementTree(xml).write(fname, pretty_print=True)

# =============================================================================

if __name__ == "__main__":
    main()
