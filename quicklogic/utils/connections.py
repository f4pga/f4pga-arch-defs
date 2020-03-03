"""
Utility functions for making hop connections between switchboxes and locat
switchbox - tile connections.
"""
import re
from data_structs import *

# =============================================================================

# A regex for regular HOP wires
RE_HOP_WIRE = re.compile(r"^([HV])([0-9])([TBLR])([0-9])")

# A regex for HOP offsets
RE_HOP = re.compile(r"^([\[\]A-Za-z0-9_]+)_([TBLR])([0-9]+)$")

# =============================================================================


def hop_to_str(offset):
    """
    Formats a two-character string that uniquely identifies the hop offset.

    >>> hop_to_str([-3, 0])
    'L3'
    >>> hop_to_str([1, 0])
    'R1'
    >>> hop_to_str([0, -2])
    'T2'
    >>> hop_to_str([0, +7])
    'B7'
    """

    # Zero offsets are not allowed
    assert offset[0] != 0 or offset[1] != 0, offset

    # Diagonal offsets are not allowed
    if offset[0] != 0:
        assert offset[1] == 0, offset
    if offset[1] != 0:
        assert offset[0] == 0, offset    

    # Horizontal
    if offset[1] == 0:
        if offset[0] > 0:
            return "R{}".format(+offset[0])
        if offset[0] < 0:
            return "L{}".format(-offset[0])

    # Vertical
    if offset[0] == 0:
        if offset[1] > 0:
            return "B{}".format(+offset[1])
        if offset[1] < 0:
            return "T{}".format(-offset[1])

    # Should not happen
    assert False, offset


def get_name_and_hop(name):
    """
    Extracts wire name and hop offset given a hop wire name. Returns a tuple
    with (name, (hop_x, hop_y)).

    When a wire name does not contain hop definition then the function
    returns (name, None).

    Note: the hop offset is defined from the input (destination) perspective.

    >>> get_name_and_hop("WIRE")
    ('WIRE', None)
    >>> get_name_and_hop("V4T0_B3")
    ('V4T0', (0, 3))
    >>> get_name_and_hop("H2R1_L1")
    ('H2R1', (-1, 0))
    >>> get_name_and_hop("RAM_A[5]_T2")
    ('RAM_A[5]', (0, -2))
    """

    # Check if the name defines a hop.
    match = RE_HOP.match(name)
    if match is None:
        return name, None

    # Hop length
    length = int(match.group(3))
    assert length in [1, 2, 3, 4], (name, length)

    # Hop direction
    direction = match.group(2)
    if direction == "T":
        hop = (0, -length)
    elif direction == "B":
        hop = (0, +length)
    elif direction == "L":
        hop = (-length, 0)
    elif direction == "R":
        hop = (+length, 0)
    else:
        assert False, (name, direction)

    return match.group(1), hop


def is_regular_hop_wire(name):
    """
    Returns True if the wire name defines a regular HOP wire. Also performs
    sanity checks of the name.

    >>> is_regular_hop_wire("H1R5")
    True
    >>> is_regular_hop_wire("V4B7")
    True
    >>> is_regular_hop_wire("WIRE")
    False
    >>> is_regular_hop_wire("MULT_Addr[17]_R3")
    False
    """

    # Match
    match = RE_HOP_WIRE.match(name)
    if match is None:
        return False

    # Check length
    length = int(match.group(2))
    assert length in [1, 2, 4], name

    # Check orientation
    orientation = match.group(1)
    direction   = match.group(3)

    if orientation == "H":
        assert direction in ["L", "R"], name
    if orientation == "V":
        assert direction in ["T", "B"], name

    return True

# =============================================================================


def build_tile_connections(tile_types, tile_grid, switchbox_types, switchbox_grid):
    """
    Build local and foreign connections between all switchboxes and tiles.
    """
    connections = []

    # Process switchboxes
    for loc, switchbox_type in switchbox_grid.items():
        switchbox = switchbox_types[switchbox_type]
        
        # Get pins
        sbox_pins = [pin for pin in switchbox.pins if pin.type in \
                    [SwitchboxPinType.LOCAL, SwitchboxPinType.FOREIGN]]

        for sbox_pin in sbox_pins:
            tile = None

            # A local connection
            if sbox_pin.type == SwitchboxPinType.LOCAL:
                pin_name = sbox_pin.name
                tile_loc = loc
                
            # A foreign connection
            elif sbox_pin.type == SwitchboxPinType.FOREIGN:

                # Get the hop offset
                pin_name, hop = get_name_and_hop(sbox_pin.name)
                assert hop is not None, sbox_pin

                tile_loc = Loc(
                    x = loc.x + hop[0],
                    y = loc.y + hop[1],
                )

            # Get the tile
            if tile_loc not in tile_grid:
                print("WARNING: No tile at loc '{}' for pin '{}'".format(tile_loc, sbox_pin.name))
                continue

            tile = tile_types[tile_grid[tile_loc].type]

            # Find the pin in the tile
            for pin in tile.pins:
                if pin.direction == OPPOSITE_DIRECTION[sbox_pin.direction]:
                    cell, name = pin.name.split("_", maxsplit=1)
                    if name == pin_name:
                        tile_pin = pin
                        break
            else:
                tile_pin = None

            # Pin not found
            if tile_pin is None:
                print("WARNING: No pin in tile at '{}' found for switchbox pin '{}' of '{}' at '{}'".format(
                    tile_loc,
                    sbox_pin.name,
                    switchbox.type,
                    loc
                ))
                continue            

            # Add the connection
            src = ConnectionLoc(
                loc=loc,
                pin=sbox_pin.name,
                type=ConnectionType.SWITCHBOX,
            )
            dst = ConnectionLoc(
                loc=loc,
                pin=tile_pin.name,
                type=ConnectionType.TILE,
            )

            if sbox_pin.direction == PinDirection.OUTPUT:
                connection = Connection(src=src, dst=dst)
            if sbox_pin.direction == PinDirection.INPUT:
                connection = Connection(src=dst, dst=src)

            connections.append(connection)

    return connections


# =============================================================================


def build_hop_connections(switchbox_types, switchbox_grid):
    """
    Builds HOP connections between switchboxes.
    """
    connections = []

    # Determine the switchbox grid limits
    xs = set([loc.x for loc in switchbox_grid.keys()])
    ys = set([loc.y for loc in switchbox_grid.keys()])
    loc_min = Loc(min(xs), min(ys))
    loc_max = Loc(max(xs), max(ys))

    # Identify all connections that go out of switchboxes
    for dst_loc, dst_switchbox_type in switchbox_grid.items():
        dst_switchbox = switchbox_types[dst_switchbox_type]

        # Process HOP inputs. No need for looping over outputs as each output
        # should go into a HOP input.
        dst_pins = [pin for pin in dst_switchbox.inputs.values() if pin.type == SwitchboxPinType.HOP]
        for dst_pin in dst_pins:

            # Parse the name, determine hop offset. Skip non-hop wires.
            hop_name, hop_ofs = get_name_and_hop(dst_pin.name)
            if hop_ofs is None:
                continue

            # Check if we don't hop outside the FPGA grid.
            src_loc = Loc(dst_loc.x + hop_ofs[0], dst_loc.y + hop_ofs[1])
            if src_loc.x < loc_min.x or src_loc.x > loc_max.x:
                continue
            if src_loc.y < loc_min.y or src_loc.y > loc_max.y:
                continue

            # Get the switchbox at the source location
            if src_loc not in switchbox_grid:
                print("WARNING: No switchbox at '{}' for input '{}' of switchbox '{}' at '{}'".format(
                    src_loc, dst_pin.name, dst_switchbox_type, dst_loc
                ))
                continue

            src_switchbox_type = switchbox_grid[src_loc]
            src_switchbox      = switchbox_types[src_switchbox_type]

            # Check if there is a matching input pin in that switchbox
            src_pins = [pin for pin in src_switchbox.outputs.values() if pin.name == hop_name]

            if len(src_pins) != 1:
                print("WARNING: No output pin '{}' in switchbox '{}' at '{}' for input '{}' of switchbox '{}' at '{}'".format(
                    hop_name, src_switchbox_type, src_loc, dst_pin.name, dst_switchbox_type, dst_loc
                ))
                continue

            src_pin = src_pins[0]

            # Add the connection
            connection = Connection(
                src=ConnectionLoc(
                    loc=src_loc,
                    pin=src_pin.name,
                    type=ConnectionType.SWITCHBOX,
                ),
                dst=ConnectionLoc(
                    loc=dst_loc,
                    pin=dst_pin.name,
                    type=ConnectionType.SWITCHBOX,
                ),
            )

            connections.append(connection)

    return connections

# =============================================================================


def build_connections(tile_types, tile_grid, switchbox_types, switchbox_grid):
    """
    Builds a connection map between switchboxes in the grid and between
    switchboxes and underlying tiles.
    """
    connections = []

    # Local and foreign tile connections
    connections += build_tile_connections(tile_types, tile_grid, switchbox_types, switchbox_grid)

    # HOP connections
    connections += build_hop_connections(switchbox_types, switchbox_grid)

    return connections


def check_connections(connections):
    """
    Check if all connections are sane.
     - All connections should be point-to-point. No fanin/fanouts.
    """

    # Check if there are no duplicated connections going to the same destination
    dst_conn_locs = set()
    for connection in connections:
        if connection.dst in dst_conn_locs:
            print("ERROR: Duplicate destination '{}'".format(connection.dst))
        dst_conn_locs.add(connection.dst)
