#!/usr/bin/env python3
"""
Functions related to parsing and processing of data stored in a QuickLogic
TechFile.
"""
from copy import deepcopy
import itertools
import argparse
from collections import defaultdict
import pickle
import re

import lxml.etree as ET

from data_structs import *
from connections import build_connections, check_connections
from connections import hop_to_str, get_name_and_hop, is_regular_hop_wire

# =============================================================================

# A list of cells in the global clock network
GCLK_CELLS = (
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


def update_switchbox_pins(switchbox):
    """
    Identifies top-level inputs and outputs of the switchbox and updates lists
    of them.
    """
    switchbox.inputs  = {}
    switchbox.outputs = {}

    # Top-level inputs and their locations. Indexed by pin names.
    input_locs = defaultdict(lambda: [])

    for stage_id, stage in switchbox.stages.items():
        for switch_id, switch in stage.switches.items():
            for mux_id, mux in switch.muxes.items():

                # Add the mux output pin as top level output if necessary
                if mux.output.name is not None:

                    loc = SwitchboxPinLoc(
                        stage_id  = stage.id,
                        switch_id = switch.id,
                        mux_id    = mux.id,
                        pin_id    = 0,
                        pin_direction = PinDirection.OUTPUT
                    )

                    if stage.type == "STREET":
                        pin_type = SwitchboxPinType.LOCAL
                    else:
                        pin_type = SwitchboxPinType.HOP

                    pin = SwitchboxPin(
                        id        = len(switchbox.outputs),
                        name      = mux.output.name,
                        direction = PinDirection.OUTPUT,
                        locs      = [loc],
                        type      = pin_type
                    )

                    assert pin.name not in switchbox.outputs, pin
                    switchbox.outputs[pin.name] = pin

                # Add the mux input pins as top level inputs if necessary
                for pin in mux.inputs.values():
                    if pin.name is not None:

                        loc = SwitchboxPinLoc(
                            stage_id  = stage.id,
                            switch_id = switch.id,
                            mux_id    = mux.id,
                            pin_id    = pin.id,
                            pin_direction = PinDirection.INPUT
                        )

                        input_locs[pin.name].append(loc)

    # Add top-level input pins to the switchbox.
    keys = sorted(input_locs.keys(), key=lambda k: k[0])
    for name, locs in {k: input_locs[k] for k in keys}.items():

        # Determine the pin type
        is_hop = is_regular_hop_wire(name)
        _, hop = get_name_and_hop(name)

        if name in ["VCC", "GND"]:
            pin_type = SwitchboxPinType.CONST
        elif name.startswith("CAND"):
            pin_type = SwitchboxPinType.GCLK
        elif is_hop:
            pin_type = SwitchboxPinType.HOP
        elif hop is not None:
            pin_type = SwitchboxPinType.FOREIGN
        else:
            pin_type = SwitchboxPinType.LOCAL

        pin = SwitchboxPin(
            id          = len(switchbox.inputs),
            name        = name,
            direction   = PinDirection.INPUT,
            locs        = locs,
            type        = pin_type
        )

        assert pin.name not in switchbox.inputs, pin
        switchbox.inputs[pin.name] = pin

    return switchbox


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
            type = stage_type
        )
        switchbox.stages[stage_id] = stage

        # Process outputs
        switches = {}
        for xml_output in xml_stage.findall("Output"):
            out_id        = int(xml_output.attrib["Number"])
            out_switch_id = int(xml_output.attrib["SwitchNum"])
            out_pin_id    = int(xml_output.attrib["SwitchOutputNum"])
            out_pin_name  = xml_output.get("JointOutputName", None)

            # These indicate unconnected top-level output.
            if out_pin_name in ["-1"]:
                out_pin_name = None

            # Add a new switch if needed
            if out_switch_id not in switches:
                switches[out_switch_id] = Switchbox.Switch(out_switch_id, stage_id)
            switch = switches[out_switch_id]

            # Add a mux for the output
            mux = Switchbox.Mux(out_pin_id, switch.id)
            assert mux.id not in switch.muxes, mux
            switch.muxes[mux.id] = mux

            # Add output pin to the mux
            mux.output = SwitchPin(
                id        = 0,
                name      = out_pin_name,
                direction = PinDirection.OUTPUT
                )

            # Process inputs
            for xml_input in xml_output:
                inp_pin_id   = int(xml_input.tag.replace("Input", ""))
                inp_pin_name = xml_input.get("WireName", None)
                inp_hop_dir  = xml_input.get("Direction", None)
                inp_hop_len  = int(xml_input.get("Length", "-1"))

                # These indicate unconnected top-level input.
                if inp_pin_name in ["-1"]:
                    inp_pin_name = None

                # Append the actual wire length and hop diretion to names of
                # pins that connect to HOP wires.
                is_hop = (inp_hop_dir in ["Left", "Right", "Top", "Bottom"])
                if is_hop:
                    inp_pin_name = "{}_{}{}".format(
                        inp_pin_name,
                        inp_hop_dir[0],
                        inp_hop_len)

                # Add the input to the mux
                pin = SwitchPin(
                    id        = inp_pin_id,
                    name      = inp_pin_name,
                    direction = PinDirection.INPUT
                    )

                assert pin.id not in mux.inputs, pin
                mux.inputs[pin.id] = pin

                # Add internal connection
                if stage_type == "STREET" and stage_id > 0:
                    conn_stage_id  = int(xml_input.attrib["Stage"])
                    conn_switch_id = int(xml_input.attrib["SwitchNum"])
                    conn_pin_id    = int(xml_input.attrib["SwitchOutputNum"])

                    conn = SwitchConnection(
                        src = SwitchboxPinLoc(
                            stage_id  = conn_stage_id,
                            switch_id = conn_switch_id,
                            mux_id    = conn_pin_id,
                            pin_id    = 0,
                            pin_direction = PinDirection.OUTPUT
                            ),
                        dst = SwitchboxPinLoc(
                            stage_id  = stage.id,
                            switch_id = switch.id,
                            mux_id    = mux.id,
                            pin_id    = inp_pin_id,
                            pin_direction = PinDirection.INPUT
                            ),
                    )

                    assert conn not in switchbox.connections, conn
                    switchbox.connections.add(conn)

        # Add switches to the stage
        stage.switches = switches

    # Update top-level pins
    update_switchbox_pins(switchbox)

    return switchbox

# =============================================================================


def parse_wire_mapping_table(xml_root, switchbox_grid, switchbox_types):
    """
    Parses the "DeviceWireMappingTable" section. Returns a dict indexed by
    locations.
    """

    def yield_locs_and_maps():
        """
        Yields locations and wire mappings associated with it.
        """
        RE_LOC = re.compile(r"^(Row|Col)_([0-9]+)_([0-9]+)$")

        # Rows
        xml_rows = [e for e in xml_root if e.tag.startswith("Row_")]
        for xml_row in xml_rows:

            # Decode row range
            match = RE_LOC.match(xml_row.tag)
            assert match is not None, xml_row.tag

            row_beg = int(xml_row.attrib["RowStartNum"])
            row_end = int(xml_row.attrib["RowEndNum"])

            assert row_beg == int(match.group(2)), \
                (xml_row.tag, row_beg, row_end)
            assert row_end == int(match.group(3)), \
                (xml_row.tag, row_beg, row_end)

            # Columns
            xml_cols = [e for e in xml_row if e.tag.startswith("Col_")]
            for xml_col in xml_cols:

                # Decode column range
                match = RE_LOC.match(xml_col.tag)
                assert match is not None, xml_col.tag

                col_beg = int(xml_col.attrib["ColStartNum"])
                col_end = int(xml_col.attrib["ColEndNum"])

                assert col_beg == int(match.group(2)), \
                    (xml_col.tag, col_beg, col_end)
                assert col_end == int(match.group(3)), \
                    (xml_col.tag, col_beg, col_end)

                # Wire maps
                xml_maps = [e for e in xml_col if e.tag.startswith("Stage_")]

                # Yield wire maps for each location
                for y in range(row_beg, row_end+1):
                    for x in range(col_beg, col_end+1):
                        yield (Loc(x=x, y=y), xml_maps)

    # Process wire maps
    wire_maps = defaultdict(lambda: {})

    RE_STAGE   = re.compile(r"^Stage_([0-9])$")
    RE_JOINT   = re.compile(r"^Join\.([0-9]+)\.([0-9]+)\.([0-9]+)$")
    RE_WIREMAP = re.compile(r"^WireMap\.(Top|Bottom|Left|Right)\.Length_([0-9])\.(.*)$")

    for loc, xml_maps in yield_locs_and_maps():
        for xml_map in xml_maps:

            # Decode stage id
            match = RE_STAGE.match(xml_map.tag)
            assert match is not None, xml_map.tag

            stage_id = int(xml_map.attrib["StageNumber"])
            assert stage_id == int(match.group(1)), \
                (xml_map.tag, stage_id)

            # Decode wire joints
            joints = {k: v for k, v in xml_map.attrib.items() if k.startswith("Join.")}
            for joint_key, joint_map in joints.items():

                # Decode the joint key
                match = RE_JOINT.match(joint_key)
                assert match is not None, joint_key

                pin_loc = SwitchboxPinLoc(
                    stage_id  = stage_id,
                    switch_id = int(match.group(1)),
                    mux_id    = int(match.group(2)),
                    pin_id    = int(match.group(3)),
                    pin_direction = PinDirection.INPUT  # FIXME: Are those always inputs ?
                )

                # Decode the wire name
                match = RE_WIREMAP.match(joint_map)
                assert match is not None, joint_map

                wire_hop_dir = match.group(1)
                wire_hop_len = int(match.group(2))
                wire_name    = match.group(3)

                # Compute location of the tile that the wire is connected to
                if wire_hop_dir == "Top":
                    tile_loc = Loc(x=loc.x, y=loc.y - wire_hop_len)
                elif wire_hop_dir == "Bottom":
                    tile_loc = Loc(x=loc.x, y=loc.y + wire_hop_len)
                elif wire_hop_dir == "Left":
                    tile_loc = Loc(x=loc.x - wire_hop_len, y=loc.y)
                elif wire_hop_dir == "Right":
                    tile_loc = Loc(x=loc.x + wire_hop_len, y=loc.y)
                else:
                    assert False, wire_hop_dir

                # Append to the map
                wire_maps[loc][pin_loc] = (wire_name, tile_loc)

    return wire_maps


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


def specialize_switchboxes_with_port_maps(switchbox_types, switchbox_grid, port_maps):
    """
    Specializes switchboxes by applying port mapping.
    """

    for loc, port_map in port_maps.items():

        # No switchbox at that location
        if loc not in switchbox_grid:
            continue

        # Get the switchbox type
        switchbox_type = switchbox_grid[loc]
        switchbox = switchbox_types[switchbox_type]

        # Make a copy of the switchbox
        new_type = "{}_X{}Y{}".format(switchbox.type, loc.x, loc.y)
        new_switchbox = Switchbox(new_type)
        new_switchbox.stages      = deepcopy(switchbox.stages)
        new_switchbox.connections = deepcopy(switchbox.connections)

        # Remap pin names
        did_remap = False
        for stage_id, stage in new_switchbox.stages.items():
            for switch_id, switch in stage.switches.items():
                for mux_id, mux in switch.muxes.items():

                    # Remap output
                    pin = mux.output
                    key = (pin.name, pin.direction)
                    if key in port_map:
                        did_remap = True
                        mux.output = SwitchPin(
                            id        = pin.id,
                            name      = port_map[key],
                            direction = pin.direction,
                        )

                    # Remap inputs
                    for pin in mux.inputs.values():
                        key = (pin.name, pin.direction)
                        if key in port_map:
                            did_remap = True
                            mux.inputs[pin.id] = SwitchPin(
                                id        = pin.id,
                                name      = port_map[key],
                                direction = pin.direction,
                            )

        # Nothing remapped, discard the new switchbox
        if not did_remap:
            continue

        # Update top-level pins
        update_switchbox_pins(new_switchbox)

        # Add to the switchbox types and the grid
        switchbox_types[new_switchbox.type] = new_switchbox
        switchbox_grid[loc] = new_switchbox.type


def specialize_switchboxes_with_wire_maps(switchbox_types, switchbox_grid, port_maps, wire_maps):
    """
    Specializes switchboxes by applying wire mapping.
    """

    for loc, wire_map in wire_maps.items():

        # No switchbox at that location
        if loc not in switchbox_grid:
            continue

        # Get the switchbox type
        switchbox_type = switchbox_grid[loc]
        switchbox = switchbox_types[switchbox_type]

        # Make a copy of the switchbox
        new_type = "{}_X{}Y{}".format(switchbox.type, loc.x, loc.y)
        new_switchbox = Switchbox(new_type)
        new_switchbox.stages      = deepcopy(switchbox.stages)
        new_switchbox.connections = deepcopy(switchbox.connections)

        # Remap pin names
        did_remap = False
        for pin_loc, (wire_name, map_loc) in wire_map.items():

            # Get port map at the destination location of the wire that is
            # being remapped.
            assert map_loc in port_maps, (map_loc, wire_name)
            port_map  = port_maps[map_loc]

            # Get the actual tile pin name
            key = (wire_name, PinDirection.INPUT)
            assert key in port_map, (map_loc, key)
            pin_name = port_map[key]

            # Append the hop to the wire name. Only if the map indicates that
            # the pin is connected.
            if pin_name is not None:
                hop = (
                    map_loc.x - loc.x,
                    map_loc.y - loc.y,
                )
                pin_name += "_{}".format(hop_to_str(hop))

            # Rename pin
            stage  = new_switchbox.stages[pin_loc.stage_id]
            switch = stage.switches[pin_loc.switch_id]
            mux    = switch.muxes[pin_loc.mux_id]
            pin    = mux.inputs[pin_loc.pin_id]

            new_pin = SwitchPin(
                id        = pin.id,
                direction = pin.direction,
                name      = pin_name
            )

            mux.inputs[new_pin.id] = new_pin
            did_remap = True

        # Nothing remapped, discard the new switchbox
        if not did_remap:
            continue

        # Update top-level pins
        update_switchbox_pins(new_switchbox)

        # Add to the switchbox types and the grid
        switchbox_types[new_switchbox.type] = new_switchbox
        switchbox_grid[loc] = new_switchbox.type

# =============================================================================


def find_special_cells(tile_grid):
    """
    Finds cells that occupy more than one tilegrid location.
    """
    cells = {}

    # Assign each cell name its locations.
    for loc, tile in tile_grid.items():
        for cell_type, cell_names in tile.cell_names.items():
            for cell_name in cell_names:

                # Skip LOGIC as it is always contained in a single tile
                if cell_name == "LOGIC":
                    continue            

                if cell_name not in cells:
                    cells[cell_name] = {
                        "type": cell_type,
                        "locs": [loc]
                    }
                else:
                    cells[cell_name]["locs"].append(loc)

    # Leave only those that have more than one location
    cells = {k: v for k, v in cells.items() if len(v["locs"]) > 1}

# =============================================================================


def get_loc_of_cell(cell_name, tile_grid):
    """
    Returns loc of a cell with the given name in the tilegrid.
    """

    # Look for a tile that has the cell
    for loc, tile in tile_grid.items():
        if tile is None:
            continue

        cell_names = [n for ns in tile.cell_names.values() for n in ns]
        if cell_name in cell_names:
            return loc

    # Not found
    return None


def parse_bidir_pinmap(xml_root, tile_grid):
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
            cell_names = []
            cell_locs = []

            # Parse cells
            for xml_cell in xml_pin.findall("cell"):
                cell_name = xml_cell.attrib["name"]
                cell_names.append(cell_name)
                cell_locs.append(get_loc_of_cell(cell_name, tile_grid))

            # Cannot be more than one loc
            assert len(set(cell_locs)) == 1, (pkg_name, pin_name, cell_names, cell_locs)
            loc = cell_locs[0]
            
            # Location not found
            if loc is None:
                print("ERROR: No loc for package pin '{}' of package '{}'".format(
                    pin_name, pkg_name))
                continue

            # Add the pin mapping
            pkg_pin_map[pin_name] = PackagePin(
                name = pin_name,
                loc = loc,
                cell_names = cell_names
            )

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

    # Get the "DeviceWireMappingTable" section
    xml_wiremap = xml_routing.find("DeviceWireMappingTable")
    assert xml_wiremap is not None

    # Import wire mapping
    wire_maps = parse_wire_mapping_table(xml_wiremap, switchbox_grid, switchbox_types)

    # Get the "DevicePortMappingTable" section
    xml_portmap = xml_routing.find("DevicePortMappingTable")
    assert xml_portmap is not None

    # Import switchbox port mapping
    port_maps = parse_port_mapping_table(xml_portmap, switchbox_grid)

    # Specialize switchboxes with wire maps
    specialize_switchboxes_with_wire_maps(switchbox_types, switchbox_grid, port_maps, wire_maps)

    # Specialize switchboxes with local port maps
    specialize_switchboxes_with_port_maps(switchbox_types, switchbox_grid, port_maps)

    # Remove switchbox types not present in the grid anymore due to their
    # specialization.
    for type in list(switchbox_types.keys()):
        if type not in switchbox_grid.values():
            del switchbox_types[type]

    # Get the "Packages" section
    xml_packages = xml_root.find("Packages")
    assert xml_packages is not None

    # Import BIDIR cell names to package pin mapping
    package_pinmaps = parse_bidir_pinmap(xml_packages, tile_grid)

    return {
        "cells_library": cells_library,
        "tile_types": tile_types,
        "tile_grid": tile_grid,
        "switchbox_types": switchbox_types,
        "switchbox_grid": switchbox_grid,
        "package_pinmaps": package_pinmaps
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
        "package_pinmaps": data["package_pinmaps"],
    }

    with open(args.db, "wb") as fp:
        pickle.dump(db_root, fp, protocol=3)

# =============================================================================


if __name__ == "__main__":
    main()

