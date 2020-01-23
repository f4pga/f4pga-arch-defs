"""
This file contains definitions of various data structutes used to hold tilegrid
and routing information of a Quicklogic FPGA.
"""
from collections import namedtuple
from enum import Enum

# =============================================================================

"""
This is a generic location in the tilegrid
"""
Loc = namedtuple("Loc", "x y")

"""
Pin direction in terms of its function.
"""
class PinDirection(Enum):
    UNSPEC = 0
    INPUT  = 1
    OUTPUT = 2

"""
Pin direction in therms where is it "standing out" of a tile.
"""
class PinSide(Enum):
    UNSPEC = 0
    NORTH  = 1
    SOUTH  = 2
    EAST   = 3
    WEST   = 4

"""
FPGA grid quadrant.
"""
Quadrant = namedtuple("Quadrant", "name x0 y0 x1 y1")

# =============================================================================


class Cell(object):
    """
    A cell within a tile representation (should be named "site" ?). Holds
    cell type, cell instance name and list of its pins.
    """

    class Pin(object):
        """
        A cell pin representation
        """
        def __init__(self, name, direction = PinDirection.UNSPEC):
            self.name      = name
            self.direction = direction

    def __init__(self, type, pins = ()):
        self.type = type
        self.pins = list(pins)

"""
A cell instance within a tile
"""
CellInstance = namedtuple("CellInstance", "type name")

# =============================================================================


class Tile(object):
    """
    A tile representation. The Quicklogic FPGA fabric does not define tiles.
    It has rather a group of cells bound to a common geographical location.
    """

    class Pin(object):
        """
        A tile pin. Bound directly to one pin of one cell. In the end should
        have a side assign.
        """
        def __init__(self, name, direction, side = PinSide.UNSPEC):
            self.name      = name
            self.direction = direction
            self.side      = side

    def __init__(self, loc, type="", name="", cells=(), quadrant=None):
        self.loc       = loc
        self.type      = type
        self.name      = name
        self.cells     = list(cells)
        self.pins      = []
        self.switchbox = None
        self.quadrant  = quadrant

    def make_type(self):
        """
        Generate the type name from cell types that the tile contains.
        """
        cell_types  = sorted([c.type for c in self.cells])
        cell_counts = {t: 0 for t in cell_types}

        for cell in self.cells:
            cell_counts[cell.type] += 1

        parts = []
        for t, c in cell_counts.items():
            if c == 1:
                parts.append(t)
            else:
                parts.append("{}x{}".format(c, t))

        self.type = "_".join(parts)

    def make_pins(self, cells_library):
        """
        Basing on the cell list and their pins generates the tile pins.
        """
        self.pins = []

        # Copy pins from all cells. Prefix their names with a cell name.
        for cell in self.cells:
            for pin in cells_library[cell.type].pins:
                name = "{}.{}".format(cell.name, pin.name)

                self.pins.append(Tile.Pin(
                    name = name,
                    direction = pin.direction
                ))

# =============================================================================


class Switchbox(object):
    """
    This class holds information about a routing switchbox of a particular type.

    A switchbox is implemented in CLOS architecture. It contains of multiple
    "stages". Outputs of previous stage go to the next one. A stage contains
    multiple switches. Each switch is a small M-to-N routing box.
    """

    # A switchbox pin
    Pin = namedtuple("Pin", "id name direction")

    # A connection within the switchbox
    Connection = namedtuple("Connection", "src_stage src_switch src_pin dst_stage dst_switch dst_pin")

    class Switch(object):
        """
        This is a sub-switchbox of a switchbox stage.
        """
        def __init__(self, id, stage):
            self.id    = id
            self.stage = stage
            self.pins  = []

    class Stage(object):
        """
        Represents a routing stage which has some attributes and consists of
        a column of Switch objects
        """
        def __init__(self, id, type=None):
            self.id       = id
            self.type     = type
            self.switches = []

    def __init__(self, type):
        self.type   = type
        self.stages = {}
        self.connections = set()
