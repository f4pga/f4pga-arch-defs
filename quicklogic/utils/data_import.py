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


RE_HOP_WIRE = re.compile(r"^([HV])([0-9])([TBLR])([0-9])$")

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
    for loc, cells in cellgrid.items():

        # Filter out global clock routing cells
        cells = [c for c in cells if c.type not in GCLK_CELLS]

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

            # Add as top level output
            if out_pin_name is not None and out_pin_name not in ["-1"]:
                switchbox.pins.add(SwitchboxPin(
                    direction=PinDirection.OUTPUT,
                    id=out_num,
                    name=out_pin_name,
                    is_local= (stage_type == "STREET"),
                ))

            # Process inputs
            for xml_input in xml_output:
                inp_pin_name = xml_input.get("WireName", None)
                inp_pin_dir  = xml_input.get("Direction", None)

                inp_pin_id  = int(xml_input.tag.replace("Input", ""))
                assert inp_pin_id < 10, inp_pin_id
                inp_pin_id += out_pin_id * 10

                # Add the input
                switch.pins.append(SwitchPin(
                    id=inp_pin_id,
                    name=inp_pin_name,
                    direction=PinDirection.INPUT
                    ))

                # Add as top level input
                if inp_pin_name is not None:
                    switchbox.pins.add(SwitchboxPin(
                        direction=PinDirection.INPUT,
                        id=-1,
                        name=inp_pin_name,
                        is_local= (inp_pin_dir == "FEEDBACK"),
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
        stage.switches = list(switches.values())

    return switchbox

# =============================================================================


def parse_hop_wire_name(name):
    """
    Extracts length, direction and index from a HOP wire name. Checks if the
    name makes sense.
    """
    match = RE_HOP_WIRE.match(name)
    assert match is not None, name

    # Length
    length = int(match.group(2))
    assert length in [1, 2, 4], (name, length)

    # Orientation
    orientation = match.group(1)

    # Hop
    direction = match.group(3)
    if direction == "T":
        assert orientation == "V", name
        hop = (0, -length)
    elif direction == "B":
        assert orientation == "V", name
        hop = (+length, 0)
    elif direction == "L":
        assert orientation == "H", name
        hop = (-length, 0)
    elif direction == "R":
        assert orientation == "H", name
        hop = (0, +length)
    else:
        assert False, (name, direction)

    # Index
    index = int(match.group(4))

    return length, hop, index,


def build_connections(tile_types, tile_grid, switchbox_types, switchbox_grid):
    """
    Builds a connection map between switchboxes in the grid and between
    switchboxes and underlying tiles.
    """
    connections = []

    # Determine the switchbox grid limits
    xs = set([loc.x for loc in switchbox_grid.keys()])
    ys = set([loc.y for loc in switchbox_grid.keys()])
    loc_min = Loc(min(xs), min(ys))
    loc_max = Loc(max(xs), max(ys))

    # Identify all connections that go out of switchboxes
    for src_loc, src_switchbox_type in switchbox_grid.items():
        src_switchbox = switchbox_types[src_switchbox_type]

        # Process local connections
        src_pins = [pin for pin in src_switchbox.pins if pin.is_local]
        for src_pin in src_pins:

            # TODO: Switchbox pin to tile pin map
            tile_pin = src_pin

            # Get the underlying tile
            if src_loc not in tile_grid:
                print("WARNING: No tile at loc '{}'".format(src_loc))
                continue
            tile = tile_types[tile_grid[src_loc].type]

            # Find the pin in the underlying tile
            dst_pin = None
            for pin in tile.pins:
                if pin.direction == OPPOSITE_DIRECTION[src_pin.direction]:
                    cell, name = pin.name.split("_", maxsplit=1)
                    if name == src_pin.name:
                        dst_pin = pin
                        break

            # Pin not found
            if dst_pin is None:
                print("WARNING: No tile pin found for switchbox pin '{}' of '{}' at '{}'".format(
                    src_pin.name,
                    src_switchbox_type,
                    src_loc
                ))
                continue            

            # Add the connection
            src = ConnectionLoc(
                loc=src_loc,
                pin=src_pin.name,
                is_direct=False,
            )
            dst = ConnectionLoc(
                loc=src_loc,
                pin=dst_pin.name,
                is_direct=True,
            )

            if src_pin.direction == PinDirection.OUTPUT:
                connection = Connection(src=src, dst=dst)
            if src_pin.direction == PinDirection.INPUT:
                connection = Connection(src=dst, dst=src)

            connections.append(connection)

        # Process HOP outputs. No need for looping over inputs as each output
        # should go into a HOP input.
        src_pins = [pin for pin in src_switchbox.pins if pin.direction == PinDirection.OUTPUT and not pin.is_local]
        for src_pin in src_pins:

            # All non-local outputs should be HOP wires.
            hop_len, hop_ofs, hop_idx = parse_hop_wire_name(src_pin.name)

            # Check if we don't hop outside the FPGA grid.
            dst_loc = Loc(src_loc.x + hop_ofs[0], src_loc.y + hop_ofs[1])
            if dst_loc.x < loc_min.x or dst_loc.x > loc_max.x:
                continue
            if dst_loc.y < loc_min.y or dst_loc.y > loc_max.y:
                continue

            # Get the switchbox at the destination location
            if dst_loc not in switchbox_grid:
                print("WARNING: No switchbox at '{}' for output '{}' of switchbox '{}' at '{}'".format(
                    dst_loc, src_pin.name, src_switchbox_type, src_loc
                ))
                continue

            dst_switchbox_type = switchbox_grid[dst_loc]
            dst_switchbox      = switchbox_types[dst_switchbox_type]

            # Check if there is a matching input pin in that switchbox
            dst_pins = [pin for pin in dst_switchbox.pins if pin.direction == PinDirection.INPUT and not pin.is_local]
            dst_pins = [pin for pin in dst_pins if pin.name == src_pin.name]

            if len(dst_pins) != 1:
                print("WARNING: No input pin '{}' in switchbox '{}' at '{}' for output of switchbox '{}' at '{}'".format(
                    src_pin.name, dst_switchbox_type, dst_loc, src_switchbox_type, src_loc
                ))
                continue

            dst_pin = dst_pins[0]

            # Add the connection
            connection = Connection(
                src=ConnectionLoc(
                    loc=src_loc,
                    pin=src_pin.name,
                    is_direct=False,
                ),
                dst=ConnectionLoc(
                    loc=dst_loc,
                    pin=dst_pin.name,
                    is_direct=False,
                ),
            )

            connections.append(connection)

    return connections

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


    return cells_library, tile_types, tile_grid, switchbox_types, switchbox_grid,


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
        default="database.pickle",
        help="Device name for the parsed 'database' file"
    )

    args = parser.parse_args()

    # Read and parse the XML techfile
    xml_tree = ET.parse(args.techfile)
    xml_techfile = xml_tree.getroot()

    # Load data from the techfile
    cells_library, tile_types, phy_tile_grid, switchbox_types, switchbox_grid, = import_data(xml_techfile)

#    # DEBUG
#    print("PHY cell types:")
#    for t in cells_library.keys():
#        print("", t)
#
#    print("PHY Tile types:")
#    for t in tile_types.keys():
#        print("", t)


#    # DEBUG
#    for sbox in switchbox_types:
#        if sbox.type != "SB_LC":
#            continue
#
#        print(sbox.type)
#
#        pins = [pin for pin in sbox.pins if pin.direction == PinDirection.INPUT]
#        pins = sorted(pins, key=lambda p: p.name)
#        for pin in pins:
#            print("", pin)
#
#        pins = [pin for pin in sbox.pins if pin.direction == PinDirection.OUTPUT]
#        pins = sorted(pins, key=lambda p: p.name)
#        for pin in pins:
#            print("", pin)

    # Build the connection map
    connections = build_connections(tile_types, phy_tile_grid, switchbox_types, switchbox_grid)

    # Prepare the database
    db_root = {
        "cells_library": cells_library,
        "tile_types": tile_types,
        "phy_tile_grid": phy_tile_grid,
        "switchbox_types": switchbox_types,
        "switchbox_grid": switchbox_grid,
        "connections": connections,
    }

    with open(args.db, "wb") as fp:
        pickle.dump(db_root, fp, protocol=3)

# =============================================================================


if __name__ == "__main__":
    main()

