"""
Functions related to parsing and processing of data stored in a QuickLogic
TechFile.
"""
import itertools
from copy import deepcopy
import lxml.etree as ET

from data_structs import *

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

                # A bus
                if xml_bus is not None:
                    lsb = int(xml_bus.attrib["lsb"])
                    msb = int(xml_bus.attrib["msb"])
                    stp = int(xml_bus.attrib["step"])
                
                    for i in range(lsb, msb+1, stp):
                        cell_pins.append(Cell.Pin(
                            name = "{}[{}]".format(xml_bus.attrib["name"], i),
                            direction = direction
                        ))

                # A single pin
                else:
                    cell_pins.append(Cell.Pin(
                        name = xml_mport.attrib["name"],
                        direction = direction
                    ))

        # Add the cell
        cells.append(Cell(
            type = cell_type,
            name = cell_name,
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


def load_logic_tiles(xml_placement, tilegrid, cell_library):

    # Load "LOGIC" tiles
    xml_logic = xml_placement.find("LOGIC")
    assert xml_logic is not None

    exceptions = set()
    xml_exceptions = xml_logic.find("EXCEPTIONS")
    if xml_exceptions is not None:
        for xml in xml_exceptions:
            tag = xml.tag.upper()

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
            assert cell_type in cell_library, cell_type

            tilegrid[loc].cells.append(
                deepcopy(cell_library[cell_type])        
            )


def load_cells_to_tilegrid(xml_placement, tilegrid, cell_library):

    def get_cell(type, new_name):
        assert type in cell_library, (type, new_name)
        cell = deepcopy(cell_library[type])
        cell.name = new_name
        return cell

    # Loop over XML entries
    for xml in xml_placement:

        # Got a "Cell" tag
        if xml.tag == "Cell":
            cell_name = xml.get("name")
            cell_type = xml.get("type")        

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
                        tile = tilegrid[loc]

                        tile.cells.append(get_cell(
                            cell_type,
                            cell_name
                        ))

            # A single cell
            if len(xml_matrices) == 0:
                x = int(xml.get("column"))
                y = int(xml.get("row"))

                loc  = Loc(x, y)
                tile = tilegrid[loc]

                tile.cells.append(get_cell(
                    cell_type,
                    cell_name
                ))

        # Got something else, parse recursively
        else:
            load_cells_to_tilegrid(xml, tilegrid, cell_library)


def parse_placement(xml_placement, cell_library):

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


    # Define the initial grid
    tilegrid = {}
    for y in range(ymin, ymax+1):
        for x in range(xmin, xmax+1):
            loc  = Loc(x, y)

            tile = Tile(
                loc=loc,
                name="TILE_X{}Y{}".format(x, y),
                quadrant=get_quadrant_for_loc(loc, quadrants),
                )
            tilegrid[loc] = tile

    # Load LOGIC tiles into it
    load_logic_tiles(xml_placement, tilegrid, cell_library)

    # Load other cells
    load_cells_to_tilegrid(xml_placement, tilegrid, cell_library)

    # Update tiles
    for tile in tilegrid.values():
        tile.make_type()
        tile.make_pins()

    # DBEUG DEBUG
#    tile = tilegrid[Loc(0, 9)]
#    print([(cell.type, cell.name) for cell in tile.cells])
#    print([p.name for p in tile.pins])

    return tilegrid

# =============================================================================


def populate_switchboxes(xml_sbox, tilegrid):
    """
    Assings each tile in the grid its switchbox type.
    """
    xmin = int(xml_sbox.attrib["ColStartNum"])
    xmax = int(xml_sbox.attrib["ColEndNum"])
    ymin = int(xml_sbox.attrib["RowStartNum"])
    ymax = int(xml_sbox.attrib["RowEndNum"])

    for y, x in itertools.product(range(ymin, ymax+1), range(xmin, xmax+1)):
        loc = Loc(x, y)

        assert loc in tilegrid
        tile = tilegrid[loc]

        assert tile.switchbox is None, (loc, tile.switchbox, xml_sbox.tag,)
        tile.switchbox = xml_sbox.tag

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
#            output_num  = int(xml_output.attrib["Number"])
            out_switch_id = int(xml_output.attrib["SwitchNum"])
            out_pin_id    = int(xml_output.attrib["SwitchOutputNum"])
            out_pin_name  = xml_output.get("JointOutputName", None)

            # Add a new switch if needed
            if out_switch_id not in switches:
                switches[out_switch_id] = Switchbox.Switch(out_switch_id, stage_id)
            switch = switches[out_switch_id]

            # Add the output
            switch.pins.append(Switchbox.Pin(
                id=out_pin_id,
                name=out_pin_name,
                direction=PinDirection.OUTPUT
                ))

#            # Add as top level output
#            if stage_id == (num_stages -1):
#                switchbox.pins.append(Port(
#                id=output_num,
#                name=output_name
#                ))

            # Process inputs
            for xml_input in xml_output:
                inp_pin_name = xml_input.get("WireName", None)

                inp_pin_id  = int(xml_input.tag.replace("Input", ""))
                assert inp_pin_id < 10, inp_pin_id
                inp_pin_id += out_pin_id * 10


                # Add the input
                switch.pins.append(Switchbox.Pin(
                    id=inp_pin_id,
                    name=inp_pin_name,
                    direction=PinDirection.INPUT
                    ))

#                # Add as top level input
#                if stage_id == 0:
#                    switchbox_inputs.append(Port(
#                        id=-1,
#                        name=input_name
#                        ))

                # Add internal connection
                if stage_type == "STREET" and stage_id > 0:
                    conn_stage     = int(xml_input.attrib["Stage"])
                    conn_switch_id = int(xml_input.attrib["SwitchNum"])
                    conn_pin_id    = int(xml_input.attrib["SwitchOutputNum"])

                    conn = Switchbox.Connection(
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
    tilegrid = parse_placement(xml_placement, cells_library)

    # Get the "Routing" section
    xml_routing = xml_root.find("Routing")
    assert xml_routing is not None

    # Import switchboxes
    switchboxes = []
    for xml_node in xml_routing:

        # Not a switchbox
        if not xml_node.tag.endswith("_SBOX"):
            continue

        # Load all "variants" of the switchbox
        xml_common = xml_node.find("COMMON_STAGES")
        for xml_sbox in xml_node:
            if xml_sbox != xml_common:

                # Parse the switchbox definition
                switchboxes.append(parse_switchbox(xml_sbox, xml_common))

                # Populate switchboxes onto the tilegrid
                populate_switchboxes(xml_sbox, tilegrid)


    # Remove empty tiles (with no cells) from the tilegrid
    for loc in list(tilegrid.keys()):
        tile = tilegrid[loc]
        if len(tile.cells) == 0:
            print("INFO: Empty tile at ({},{})".format(loc.x, loc.y))
            del tilegrid[loc]

    # Check that all tiles have switchboxes assigned
    for loc, tile in tilegrid.items():
        if tile.switchbox is None:
            print("WARNING: Tile {} of type {} without a switchbox".format(
                tile.name, tile.type))

    return tilegrid, cells_library, switchboxes,

