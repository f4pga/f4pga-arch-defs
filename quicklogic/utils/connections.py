"""
Utility functions for making hop connections between switchboxes and locat
switchbox - tile connections.
"""
import re
from data_structs import *

# =============================================================================

# A regex for HOP wires.
RE_HOP_WIRE = re.compile(r"^([HV])([0-9])([TBLR])([0-9])$")

# FIXME: A list of switchboxes to ignore for now
IGNORED_SWITCHBOX_TYPES = [
    "SB_RIGHT_IFC",
    "SB_LEFT_IFC",
    "SB_BOTTOM_IFC"
]

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
        hop = (0, +length)
    elif direction == "L":
        assert orientation == "H", name
        hop = (-length, 0)
    elif direction == "R":
        assert orientation == "H", name
        hop = (+length, 0)
    else:
        assert False, (name, direction)

    # Index
    index = int(match.group(4))

    return length, hop, index,

# =============================================================================


def build_local_connections_at(loc, switchbox, tile, port_map):
    """
    Build local connections between a switchbox and a tile at given location.
    """
    connections = []

    # Process local connections
    src_pins = [pin for pin in switchbox.pins if pin.is_local]
    for src_pin in src_pins:
        tile_pin_name = src_pin.name

        # Remap the pin name if the port map is provided        
        if port_map is not None:
            key = (src_pin.name, src_pin.direction)
            if key in port_map:
                tile_pin_name = port_map[key]

        # The pin is unconnected
        if tile_pin_name is None:
            continue

        # Find the pin in the underlying tile
        dst_pin = None
        for pin in tile.pins:
            if pin.direction == OPPOSITE_DIRECTION[src_pin.direction]:
                cell, name = pin.name.split("_", maxsplit=1)
                if name == tile_pin_name:
                    dst_pin = pin
                    break

        # Pin not found
        if dst_pin is None:
            print("WARNING: No tile pin found for switchbox pin '{}' of '{}' at '{}'".format(
                tile_pin_name,
                switchbox.type,
                loc
            ))
            continue            

        # Add the connection
        src = ConnectionLoc(
            loc=loc,
            pin=src_pin.name,
            is_direct=False,
        )
        dst = ConnectionLoc(
            loc=loc,
            pin=dst_pin.name,
            is_direct=True,
        )

        if src_pin.direction == PinDirection.OUTPUT:
            connection = Connection(src=src, dst=dst)
        if src_pin.direction == PinDirection.INPUT:
            connection = Connection(src=dst, dst=src)

        connections.append(connection)

    return connections


def build_local_connections(tile_types, tile_grid, switchbox_types, switchbox_grid, port_maps):
    """
    Build local connections between all switchboxes and their undelying tiles.
    """
    connections = []

    for loc, switchbox_type in switchbox_grid.items():
        switchbox = switchbox_types[switchbox_type]

        # TODO: Don't ignore
        if switchbox_type in IGNORED_SWITCHBOX_TYPES:
            continue

        # Get the underlying tile
        if loc not in tile_grid:
            print("WARNING: No tile at loc '{}'".format(loc))
            continue
        tile = tile_types[tile_grid[loc].type]

        # Get the port map
        if loc in port_maps:
            port_map = port_maps[loc]
        else:
            port_map = None

        # Build connections
        connections += build_local_connections_at(loc, switchbox, tile, port_map)

    return connections


# =============================================================================


def build_hop_connections(tile_types, tile_grid, switchbox_types, switchbox_grid, port_maps):
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
    for src_loc, src_switchbox_type in switchbox_grid.items():
        src_switchbox = switchbox_types[src_switchbox_type]

        # TODO: Don't ignore
        if src_switchbox_type in IGNORED_SWITCHBOX_TYPES:
            continue

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


def build_connections(tile_types, tile_grid, switchbox_types, switchbox_grid, port_maps):
    """
    Builds a connection map between switchboxes in the grid and between
    switchboxes and underlying tiles.
    """
    connections = []

    # Local connections
    connections += build_local_connections(tile_types, tile_grid, switchbox_types, switchbox_grid, port_maps)

    # HOP connections
    connections += build_hop_connections(tile_types, tile_grid, switchbox_types, switchbox_grid, port_maps)

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

# This is not an error
#    # Check if there are no duplicated connections going from the same source
#    src_conn_locs = set()
#    for connection in connections:
#        if connection.src in src_conn_locs:
#            print("ERROR: Duplicate source '{}'".format(connection.src))
#        src_conn_locs.add(connection.src)
