"""
This file contains definitions of various data structutes used to hold tilegrid
and routing information of a Quicklogic FPGA.
"""
from collections import namedtuple
from enum import Enum

# =============================================================================

"""
Pin direction in terms of its function.
"""
class PinDirection(Enum):
    UNSPEC = 0
    INPUT  = 1
    OUTPUT = 2

"""
A generic pin
"""
Pin = namedtuple("Pin", "name direction")

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
This is a generic location in the tilegrid
"""
Loc = namedtuple("Loc", "x y")

"""
FPGA grid quadrant.
"""
Quadrant = namedtuple("Quadrant", "name x0 y0 x1 y1")

# =============================================================================

"""
A cell type within a tile type representation (should be named "site" ?).
Holds the cell type name and the list of its pins.
"""
CellType = namedtuple("CellType", "type pins")

"""
A cell instance within a tile. Binds a cell name with its type.
"""
Cell = namedtuple("Cell", "type name")

# =============================================================================

class TileType(object):
    """
    A tile type representation. The Quicklogic FPGA fabric does not define tiles.
    It has rather a group of cells bound to a common geographical location.
    """

    def __init__(self,  type="", cells=()):
        self.type      = type
        self.cells     = list(cells)
        self.pins      = []

    def make_pins(self, cells_library):
        """
        Basing on the cell list and their pins generates the tile pins.
        """
        self.pins = []

        # Copy pins from all cells. Prefix their names with a cell name.
        for cell in self.cells:
            for pin in cells_library[cell.type].pins:
                name = "{}.{}".format(cell.name, pin.name)

                self.pins.append(Pin(
                    name = name,
                    direction = pin.direction
                ))

"""
A tile instance within a tilegrid
"""
Tile = namedtuple("Tile", "type name")

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
