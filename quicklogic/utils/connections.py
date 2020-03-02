"""
Utility functions for making hop connections between switchboxes and locat
switchbox - tile connections.
"""
import re
from data_structs import *

# =============================================================================

# A regex for HOP wires.
RE_HOP_WIRE = re.compile(r"^([HV])([0-9])([TBLR])([0-9])_([TBLR])([0-9])$")

# =============================================================================


def parse_hop_wire_name(name):
    """
    Extracts wire name and hop offset given a hop wire name. Returns a tuple
    with (name, (hop_x, hop_y)). Checks if the wire name is sane. Returns a
    tuple with (None, None) if the wire is not a hop wire.

    Note: the hop offset is defined from the output (source) perspective.

    >>> parse_hop_wire_name("WIRE")
    (None, None)
    >>> parse_hop_wire_name("V4T0_B3")
    ('V4T0', (0, -3))
    >>> parse_hop_wire_name("H2R1_L1")
    ('H2R1', (1, 0))
    """

    match = RE_HOP_WIRE.match(name)
    if match is None:
        return None, None

    # Orientation
    orientation = match.group(1)

    # Hop length
    length = int(match.group(6))
    assert length in [1, 2, 3, 4], (name, length)

    # Hop direction
    direction = match.group(5)
    if direction == "T":
        assert orientation == "V", name
        hop = (0, +length)
    elif direction == "B":
        assert orientation == "V", name
        hop = (0, -length)
    elif direction == "L":
        assert orientation == "H", name
        hop = (+length, 0)
    elif direction == "R":
        assert orientation == "H", name
        hop = (-length, 0)
    else:
        assert False, (name, direction)

    # Name
    name = name.split("_", maxsplit=1)[0]

    return name, hop

# =============================================================================


def build_local_connections_at(loc, switchbox, tile):
    """
    Build local connections between a switchbox and a tile at given location.
    """
    connections = []

    # Process local connections
    src_pins = [pin for pin in switchbox.pins if pin.type == SwitchboxPinType.LOCAL]
    for src_pin in src_pins:

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
                switchbox.type,
                loc
            ))
            continue            

        # Add the connection
        src = ConnectionLoc(
            loc=loc,
            pin=src_pin.name,
            type=ConnectionType.SWITCHBOX,
        )
        dst = ConnectionLoc(
            loc=loc,
            pin=dst_pin.name,
            type=ConnectionType.TILE,
        )

        if src_pin.direction == PinDirection.OUTPUT:
            connection = Connection(src=src, dst=dst)
        if src_pin.direction == PinDirection.INPUT:
            connection = Connection(src=dst, dst=src)

        connections.append(connection)

    return connections


def build_local_connections(tile_types, tile_grid, switchbox_types, switchbox_grid):
    """
    Build local connections between all switchboxes and their undelying tiles.
    """
    connections = []

    for loc, switchbox_type in switchbox_grid.items():
        switchbox = switchbox_types[switchbox_type]

        # Get the underlying tile
        if loc not in tile_grid:
            print("WARNING: No tile at loc '{}'".format(loc))
            continue
        tile = tile_types[tile_grid[loc].type]

        # Build connections
        connections += build_local_connections_at(loc, switchbox, tile)

    return connections


# =============================================================================


def build_hop_connections(tile_types, tile_grid, switchbox_types, switchbox_grid):
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
            hop_name, hop_ofs = parse_hop_wire_name(dst_pin.name)
            if hop_name is None:
                continue

            # Reverse the hop offset as we are looking from the input side
            hop_ofs = (-hop_ofs[0], -hop_ofs[1])

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

    # Local connections
    connections += build_local_connections(tile_types, tile_grid, switchbox_types, switchbox_grid)

    # HOP connections
    connections += build_hop_connections(tile_types, tile_grid, switchbox_types, switchbox_grid)

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
