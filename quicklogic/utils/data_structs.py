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
An opposite direction map
"""
OPPOSITE_DIRECTION = {
    PinDirection.UNSPEC: PinDirection.UNSPEC,
    PinDirection.INPUT:  PinDirection.OUTPUT,
    PinDirection.OUTPUT: PinDirection.INPUT,
}

"""
A generic pin
"""
Pin = namedtuple("Pin", "name direction is_clock")

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

"""
Forwads and backward location mapping
"""
LocMap = namedtuple("LocMap", "fwd bwd")

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

    def __init__(self,  type, cells):
        self.type      = type
        self.cells     = cells
        self.pins      = []

    def make_pins(self, cells_library):
        """
        Basing on the cell list and their pins generates the tile pins.
        """
        self.pins = []

        # Copy pins from all cells. Prefix their names with a cell name.
        for cell_type, cell_count in self.cells.items():
            for i in range(cell_count):
                for pin in cells_library[cell_type].pins:
                    name = "{}{}_{}".format(cell_type, i, pin.name)

                    self.pins.append(Pin(
                        name = name,
                        direction = pin.direction,
                        is_clock = pin.is_clock
                    ))

"""
A tile instance within a tilegrid
"""
Tile = namedtuple("Tile", "type name cell_names")

# =============================================================================

"""
A top-level switchbox pin.

id          - Pin id.
name        - Pin name.
is_local    - True when the pin connects to/from the tile of the switchbox.
direction   - Pin direction.
"""
SwitchboxPin = namedtuple("SwitchboxPin", "id name is_local direction")

"""
A switch pin within a switchbox

id          - Pin id.
name        - Pin name. Only for top-level pins. For others is None.
direction   - Pin direction.
"""
SwitchPin = namedtuple("SwitchPin", "id name direction")

"""
A connection within a switchbox

*_stage     - Endpoint stage id.
*_switch    - Endpoint switch id within the stage.
*_pin       - Endpoint switch pin id.
"""
SwitchConnection = namedtuple("SwitchConnection", 
    "src_stage src_switch src_pin dst_stage dst_switch dst_pin")

# =============================================================================


class Switchbox(object):
    """
    This class holds information about a routing switchbox of a particular type.

    A switchbox is implemented in CLOS architecture. It contains of multiple
    "stages". Outputs of previous stage go to the next one. A stage contains
    multiple switches. Each switch is a small M-to-N routing box.
    """

    class Switch(object):
        """
        This is a sub-switchbox of a switchbox stage.
        """
        def __init__(self, id, stage):
            self.id    = id
            self.stage = stage
            self.pins  = []
            self.mux   = {}

    class Stage(object):
        """
        Represents a routing stage which has some attributes and consists of
        a column of Switch objects
        """
        def __init__(self, id, type=None):
            self.id       = id
            self.type     = type
            self.switches = {}

    def __init__(self, type):
        self.type   = type
        self.pins   = set()
        self.stages = {}
        self.connections = set()

# =============================================================================

# A connection endpoint location. Specifies location and pin name. If the
# is_direct is true then the pin name refers to the tile, if not then to the
# switchbox
ConnectionLoc = namedtuple("ConnectionLoc", "loc pin is_direct")

# A connection within the tilegrid
Connection = namedtuple("Connection", "src dst")

# =============================================================================

# A package pin. Holds information about what cells the pin cooresponds to and
# where it is in the tilegrid.
PackagePin = namedtuple("PackagePin", "name loc cell_names")
