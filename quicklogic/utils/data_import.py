#!/usr/bin/env python3
"""
Functions related to parsing and processing of data stored in a QuickLogic
TechFile.
"""
import itertools
import argparse
from collections import defaultdict
import pickle
import re

import lxml.etree as ET

from data_structs import *
from connections import build_connections, check_connections

# =============================================================================

# A list of cells in the globla clock network
GCLK_CELLS = (
    "CLOCK",
    "GMUX",
    "QMUX",
    "CAND"
)

# A List of cells and their pins which are clocks
CLOCK_PINS = {
    "LOGIC": ("QCK",),
}

# =============================================================================


def parse_library(xml_library):
    """
    Loads cell definitions from the XML
    """

    cells = []

    for xml_node in xml_library:
        
        # Skip those
        if xml_node.tag in ["PortProperties"]:
            continue

        cell_type = xml_node.tag
        cell_name = xml_node.get("name", xml_node.tag)
        cell_pins = []

        # Load pins
        for xml_pins in itertools.chain(xml_node.findall("INPUT"), 
                                        xml_node.findall("OUTPUT")):

            # Pin direction
            if xml_pins.tag == "INPUT":
                direction = PinDirection.INPUT
            elif xml_pins.tag == "OUTPUT":
                direction = PinDirection.OUTPUT
            else:
                assert False, xml_pins.tag
            
            # "mport"
            for xml_mport in xml_pins:
                xml_bus = xml_mport.find("bus")

                # Check if the port is routable. Skip it if it is not.
                is_routable = xml_mport.get("routable", "true") == "true"
                if not is_routable:
                    continue

                # A bus
                if xml_bus is not None:
                    lsb = int(xml_bus.attrib["lsb"])
                    msb = int(xml_bus.attrib["msb"])
                    stp = int(xml_bus.attrib["step"])
                
                    for i in range(lsb, msb+1, stp):
                        cell_pins.append(Pin(
                            name = "{}[{}]".format(xml_bus.attrib["name"], i),
                            direction = direction,
                            is_clock = False,
                        ))

                # A single pin
                else:
                    name = xml_mport.attrib["name"]
                    cell_pins.append(Pin(
                        name = name,
                        direction = direction,
                        is_clock = cell_type in CLOCK_PINS and name in CLOCK_PINS[cell_type],
                    ))

        # Add the cell
        cells.append(CellType(
            type = cell_type,
            pins = cell_pins
        ))

    return cells

# =============================================================================


def get_quadrant_for_loc(loc, quadrants):
    """
    Assigns a quadrant to the given location. Returns None if no one matches.
    """

    for quadrant in quadrants.values():
        if loc.x >= quadrant.x0 and loc.x <= quadrant.x1:
            if loc.y >= quadrant.y0 and loc.y <= quadrant.y1:
                return quadrant

    return None


def load_logic_cells(xml_placement, cellgrid, cells_library):

    # Load "LOGIC" tiles
    xml_logic = xml_placement.find("LOGIC")
    assert xml_logic is not None

    exceptions = set()
    xml_exceptions = xml_logic.find("EXCEPTIONS")
    if xml_exceptions is not None:
        for xml in xml_exceptions:
            tag = xml.tag.upper()

            # FIXME: Is this connect decoding of those werid loc specs?
            x = ord(tag[0]) - ord("A")
            y = int(tag[1:])

            exceptions.add(Loc(x=x, y=y))

    xml_logicmatrix = xml_logic.find("LOGICMATRIX")
    assert xml_logicmatrix is not None

    x0 = int(xml_logicmatrix.get("START_COLUMN"))
    nx = int(xml_logicmatrix.get("COLUMNS"))
    y0 = int(xml_logicmatrix.get("START_ROW"))
    ny = int(xml_logicmatrix.get("ROWS"))

    for j in range(ny):
        for i in range(nx):
            loc = Loc(x0+i, y0+j)

            if loc in exceptions:
                continue

            cell_type = "LOGIC"
            assert cell_type in cells_library, cell_type

            cellgrid[loc].append(Cell(
                type = cell_type,
                name = cell_type,
            ))


def load_other_cells(xml_placement, cellgrid, cells_library):

    # Loop over XML entries
    for xml in xml_placement:

        # Got a "Cell" tag
        if xml.tag == "Cell":
            cell_name = xml.get("name")
            cell_type = xml.get("type")        

            assert cell_type in cells_library, (cell_type, cell_name,)

            # Cell matrix
            xml_matrices = [x for x in xml if x.tag.startswith("Matrix")] 
            for xml_matrix in xml_matrices:
                x0 = int(xml_matrix.get("START_COLUMN"))
                nx = int(xml_matrix.get("COLUMNS"))
                y0 = int(xml_matrix.get("START_ROW"))
                ny = int(xml_matrix.get("ROWS"))

                for j in range(ny):
                    for i in range(nx):
                        loc  = Loc(x0+i, y0+j)

                        cellgrid[loc].append(Cell(
                            type = cell_type,
                            name = cell_name,
                        ))

            # A single cell
            if len(xml_matrices) == 0:
                x = int(xml.get("column"))
                y = int(xml.get("row"))

                loc  = Loc(x, y)

                cellgrid[loc].append(Cell(
                    type = cell_type,
                    name = cell_name,
                ))

        # Got something else, parse recursively
        else:
            load_other_cells(xml, cellgrid, cells_library)


def make_tile_type_name(cells):
    """
    Generate the tile type name from cell types
    """
    cell_types  = sorted([c.type for c in cells])
    cell_counts = {t: 0 for t in cell_types}

    for cell in cells:
        cell_counts[cell.type] += 1

    parts = []
    for t, c in cell_counts.items():
        if c == 1:
            parts.append(t)
        else:
            parts.append("{}x{}".format(c, t))

    return "_".join(parts)


def parse_placement(xml_placement, cells_library):

    # Load tilegrid quadrants
    quadrants = {}

    xml_quadrants = xml_placement.find("Quadrants")
    assert xml_quadrants is not None

    xmin = None
    xmax = None
    ymin = None
    ymax = None

    for xml_quadrant in xml_quadrants:
        name = xml_quadrant.get("name")
        x0 = int(xml_quadrant.get("ColStartNum"))
        x1 = int(xml_quadrant.get("ColEndNum"))
        y0 = int(xml_quadrant.get("RowStartNum"))
        y1 = int(xml_quadrant.get("RowEndNum"))        

        quadrants[name] = Quadrant(
            name=name,
            x0=x0,
            x1=x1,
            y0=y0,
            y1=y1,
            )

        xmin = min(xmin, x0) if xmin is not None else x0
        xmax = max(xmax, x1) if xmax is not None else x1
        ymin = min(ymin, y0) if ymin is not None else y0
        ymax = max(ymax, y1) if ymax is not None else y1


    # Define the initial tile grid. Group cells with the same location
    # together.
    cellgrid = defaultdict(lambda: [])

    # Load LOGIC cells into it
    load_logic_cells(xml_placement, cellgrid, cells_library)
    # Load other cells
    load_other_cells(xml_placement, cellgrid, cells_library)

    # Assign each location with a tile type name generated basing on cells
    # present there.
    tile_types = {}
    tile_types_at_loc = {}
    cell_names_at_loc = {}
    for loc, cells in cellgrid.items():

        # Filter out global clock routing cells
        cells = [c for c in cells if c.type not in GCLK_CELLS]

        # Collect cell names
        cell_names = defaultdict(lambda: [])
        for cell in cells:
            cell_names[cell.type].append(cell.name)        
        cell_names_at_loc[loc] = dict(cell_names)

        # Generate type and assign
        type = make_tile_type_name(cells)
        tile_types_at_loc[loc] = type

        # A new type? complete its definition
        if type not in tile_types:

            cell_types = [c.type for c in cells]
            cell_count = {t: len([c for c in cells if c.type == t]) for t in cell_types}

            tile_type = TileType(type, cell_count)
            tile_type.make_pins(cells_library)
            tile_types[type] = tile_type


    # Make the final tilegrid
    tilegrid = {}
    for loc, type in tile_types_at_loc.items():
        tilegrid[loc] = Tile(
            type = type,
            name = "TILE_X{}Y{}".format(loc.x, loc.y),
            cell_names = cell_names_at_loc[loc]
        )

    return tile_types, tilegrid


def populate_switchboxes(xml_sbox, switchbox_grid):
    """
    Assings each tile in the grid its switchbox type.
    """
    xmin = int(xml_sbox.attrib["ColStartNum"])
    xmax = int(xml_sbox.attrib["ColEndNum"])
    ymin = int(xml_sbox.attrib["RowStartNum"])
    ymax = int(xml_sbox.attrib["RowEndNum"])

    for y, x in itertools.product(range(ymin, ymax+1), range(xmin, xmax+1)):
        loc = Loc(x, y)

        assert loc not in switchbox_grid, loc
        switchbox_grid[loc] = xml_sbox.tag

# =============================================================================


def parse_switchbox(xml_sbox, xml_common = None):
    """
    Parses the switchbox definition from XML. Returns a Switchbox object
    """
    switchbox = Switchbox(type=xml_sbox.tag)

    # Identify stages. Append stages from the "COMMON_STAGES" section if
    # given.
    stages = [n for n in xml_sbox if n.tag.startswith("STAGE")]

    if xml_common is not None:
        common_stages = [n for n in xml_common if n.tag.startswith("STAGE")]
        stages.extend(common_stages)

    # Load stages
    for xml_stage in stages:

        # Get stage id
        stage_id  = int(xml_stage.attrib["StageNumber"])
        assert stage_id not in switchbox.stages, (stage_id, switchbox.stages.keys())

        stage_type = xml_stage.attrib["StageType"]

        # Add the new stage
        stage = Switchbox.Stage(
            id   = stage_id,
            type = xml_stage.attrib["StageType"]
        )
        switchbox.stages[stage_id] = stage

        # Process outputs
        switches = {}
        for xml_output in xml_stage.findall("Output"):
            out_num       = int(xml_output.attrib["Number"])
            out_switch_id = int(xml_output.attrib["SwitchNum"])
            out_pin_id    = int(xml_output.attrib["SwitchOutputNum"])
            out_pin_name  = xml_output.get("JointOutputName", None)

            # Add a new switch if needed
            if out_switch_id not in switches:
                switches[out_switch_id] = Switchbox.Switch(out_switch_id, stage_id)
            switch = switches[out_switch_id]

            # Add the output
            switch.pins.append(SwitchPin(
                id=out_pin_id,
                name=out_pin_name,
                direction=PinDirection.OUTPUT
                ))

            # Add the output to the mux
            switch.mux[out_pin_id] = []

            # Add as top level output
            if out_pin_name is not None and out_pin_name not in ["-1"]:
                switchbox.pins.add(SwitchboxPin(
                    direction=PinDirection.OUTPUT,
                    id=out_num,
                    name=out_pin_name,
                    is_local=(stage_type == "STREET")
                ))

            # Process inputs
            for xml_input in xml_output:
                inp_pin_name = xml_input.get("WireName", None)
                inp_pin_dir  = xml_input.get("Direction", None)

                inp_pin_id  = int(xml_input.tag.replace("Input", ""))

                # TODO: Will fail if there is more than 10 inputs
                assert inp_pin_id < 10, inp_pin_id
                inp_pin_id += out_pin_id * 10

                # Add the input
                switch.pins.append(SwitchPin(
                    id=inp_pin_id,
                    name=inp_pin_name,
                    direction=PinDirection.INPUT
                    ))

                # Add to the mux
                switch.mux[out_pin_id].append(inp_pin_id)

                # Add as top level input
                if inp_pin_name is not None:
                    switchbox.pins.add(SwitchboxPin(
                        direction=PinDirection.INPUT,
                        id=-1,
                        name=inp_pin_name,
                        is_local=(inp_pin_dir == "FEEDBACK")
                        ))

                # Add internal connection
                if stage_type == "STREET" and stage_id > 0:
                    conn_stage     = int(xml_input.attrib["Stage"])
                    conn_switch_id = int(xml_input.attrib["SwitchNum"])
                    conn_pin_id    = int(xml_input.attrib["SwitchOutputNum"])

                    conn = SwitchConnection(
                        src_stage=conn_stage,
                        src_switch=conn_switch_id,
                        src_pin=conn_pin_id,
                        dst_stage=stage_id,
                        dst_switch=switch.id,
                        dst_pin=inp_pin_id
                    )

                    assert conn not in switchbox.connections, conn
                    switchbox.connections.add(conn)

        # Add switches to the stage
        stage.switches = switches

    return switchbox

# =============================================================================


def parse_port_mapping_table(xml_root, switchbox_grid):
    """
    Parses switchbox port mapping tables. Returns a dict indexed by locations
    containing a dict with switchbox port to tile port name correspondence.
    """
    port_maps = defaultdict(lambda: {})

    # Sections are named "*_Table"
    xml_tables = [e for e in xml_root if e.tag.endswith("_Table")]
    for xml_table in xml_tables:

        # Get the origin
        origin = xml_table.tag.split("_")[0]
        assert origin in ["Left", "Right", "Top", "Bottom"], origin

        # Get switchbox types affected by the mapping
        sbox_types_xml = xml_table.find("SBoxTypes")
        assert sbox_types_xml is not None
        switchbox_types = set([v for k, v in sbox_types_xml.attrib.items() if k.startswith("type")])

        # Get their locations
        locs = [loc for loc, type in switchbox_grid.items() if type in switchbox_types]

        # Get the first occurrence of a switchbox with one of considered types
        # that is closes to the (0, 0) according to manhattan distance.
        base_loc = None
        for loc in locs:
            if not base_loc:
                base_loc = loc
            elif (loc.x + loc.y) < (base_loc.x + base_loc.y):
                base_loc = loc

        # Parse the port mapping table(s)
        for port_mapping_xml in xml_table.findall("PortMappingTable"):

            # Get the direction of the switchbox offset
            orientation = port_mapping_xml.attrib["Orientation"]
            if orientation == "Horizontal":
                assert origin in ["Top", "Bottom"], (origin, orientation)
                dx, dy = (+1,  0)
            elif orientation == "Vertical":
                assert origin in ["Left", "Right"], (origin, orientation)
                dx, dy = ( 0, +1)

            # Process the mapping of switchbox output ports
            for index_xml in port_mapping_xml.findall("Index"):
                pin_name = index_xml.attrib["Mapped_Interface_Name"]
                output_num = index_xml.attrib["SwitchOutputNum"]

                # Determine the mapped port direction
                if output_num == "-1":
                    pin_direction = PinDirection.INPUT
                else:
                    pin_direction = PinDirection.OUTPUT

                sbox_xmls = [e for e in index_xml if e.tag.startswith("SBox")]
                for sbox_xml in sbox_xmls:

                    offset = int(sbox_xml.attrib["Offset"])
                    mapped_name = sbox_xml.get("MTB_PortName", None)

                    # "-1" means unconnected
                    if mapped_name == "-1":
                        mapped_name = None

                    # Get the location for the map
                    loc = Loc(
                        x = base_loc.x + dx * offset,
                        y = base_loc.y + dy * offset,
                    )

                    # Append mapping
                    key = (pin_name, pin_direction)
                    assert key not in port_maps[loc], (loc, key)

                    port_maps[loc][key] = mapped_name

    # Make a normal dict
    port_maps = dict(port_maps)

    return port_maps


# =============================================================================


def parse_bidir_pinmap(xml_root):
    """
    Parses the "Package" section that holds IO pin to BIDIR cell map.

    Returns a dict indexed by package name. That dict holds another dicts
    that are indexed by IO pin names. They contain lists of BIDIR cell names
    that the IO pin is physically connected to.
    """
    pin_map = {}

    # Parse "PACKAGE" sections.
    for xml_package in xml_root.findall("PACKAGE"):

        # Initialize map
        pkg_name = xml_package.attrib["name"] 
        pkg_pin_map = {}
        pin_map[pkg_name] = pkg_pin_map

        xml_pins = xml_package.find("Pins")
        assert xml_pins is not None

        # Parse pins        
        for xml_pin in xml_pins.findall("Pin"):
            pin_name = xml_pin.attrib["name"]
            pkg_pin_map[pin_name] = []

            # Parse cells
            for xml_cell in xml_pin.findall("cell"):
                cell_name = xml_cell.attrib["name"]
                pkg_pin_map[pin_name].append(cell_name)

    return pin_map

# =============================================================================


def import_data(xml_root):
    """
    Imports the Quicklogic FPGA tilegrid and routing data from the given
    XML tree
    """

    # Get the "Library" section
    xml_library = xml_root.find("Library")
    assert xml_library is not None

    # Import cells from the library
    cells = parse_library(xml_library)

    # Get the "Placement" section
    xml_placement = xml_root.find("Placement")
    assert xml_placement is not None

    cells_library = {cell.type: cell for cell in cells}
    tile_types, tile_grid = parse_placement(xml_placement, cells_library)

    # Get the "Routing" section
    xml_routing = xml_root.find("Routing")
    assert xml_routing is not None

    # Import switchboxes
    switchbox_grid  = {}
    switchbox_types = {}
    for xml_node in xml_routing:

        # Not a switchbox
        if not xml_node.tag.endswith("_SBOX"):
            continue

        # Load all "variants" of the switchbox
        xml_common = xml_node.find("COMMON_STAGES")
        for xml_sbox in xml_node:
            if xml_sbox != xml_common:

                # Parse the switchbox definition
                switchbox = parse_switchbox(xml_sbox, xml_common)

                assert switchbox.type not in switchbox_types, switchbox.type
                switchbox_types[switchbox.type] = switchbox

                # Populate switchboxes onto the tilegrid
                populate_switchboxes(xml_sbox, switchbox_grid)

    # Get the "DevicePortMappingTable" section
    xml_portmap = xml_routing.find("DevicePortMappingTable")
    assert xml_portmap is not None

    # Import switchbox port mapping
    port_maps = parse_port_mapping_table(xml_portmap, switchbox_grid)

    # Get the "Packages" section
    xml_packages = xml_root.find("Packages")
    assert xml_packages is not None

    # Import BIDIR cell names to package pin mapping
    package_pinmap = parse_bidir_pinmap(xml_packages)

    return {
        "cells_library": cells_library,
        "tile_types": tile_types,
        "tile_grid": tile_grid,
        "switchbox_types": switchbox_types,
        "switchbox_grid": switchbox_grid,
        "port_maps": port_maps,
        "package_pinmap": package_pinmap
    }


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
        "--db",
        type=str,
        default="phy_database.pickle",
        help="Device name for the parsed 'database' file"
    )

    args = parser.parse_args()

    # Read and parse the XML techfile
    xml_tree = ET.parse(args.techfile)
    xml_techfile = xml_tree.getroot()

    # Load data from the techfile
    data = import_data(xml_techfile)

    # Build the connection map
    connections = build_connections(
        data["tile_types"],
        data["tile_grid"],
        data["switchbox_types"],
        data["switchbox_grid"],
        data["port_maps"],
        )

    check_connections(connections)

    # Prepare the database
    db_root = {
        "cells_library": data["cells_library"],
        "tile_types": data["tile_types"],
        "phy_tile_grid": data["tile_grid"],
        "switchbox_types": data["switchbox_types"],
        "switchbox_grid": data["switchbox_grid"],
        "connections": connections,
    }

    with open(args.db, "wb") as fp:
        pickle.dump(db_root, fp, protocol=3)

# =============================================================================


if __name__ == "__main__":
    main()

