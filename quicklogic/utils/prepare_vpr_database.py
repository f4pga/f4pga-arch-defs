#!/usr/bin/env python3
import argparse
import pickle
import itertools

from data_structs import *

# =============================================================================


def is_loc_within_limit(loc, limit):
    """
    Returns true when the given location lies within the given limit.
    Returns true if the limit is None. Coordinates in the limit are
    inclusive.
    """

    if limit is None:
        return True

    if loc.x < limit[0] or loc.x > limit[2]:
        return False
    if loc.y < limit[1] or loc.y > limit[3]:
        return False

    return True

# =============================================================================


def add_synthetic_cell_and_tile_types(tile_types, cells_library):

    # The synthetic IO PAD cell.
    cell_type = CellType(
        type = "SYN_PAD",
        pins = (
            Pin(name="I", is_clock=False, direction=PinDirection.INPUT),
            Pin(name="O", is_clock=False, direction=PinDirection.OUTPUT),
        )
    )
    cells_library[cell_type.type] = cell_type

    # The synthetic IO tile.
    tile_type = TileType("SYN_IO", {"SYN_PAD": 1})
    tile_type.make_pins(cells_library)
    tile_types[tile_type.type] = tile_type


def process_tilegrid(tile_types, tile_grid, grid_limit=None):
    """
    Processes the tilegrid. May add/remove tiles. Returns a new one.
    """

    # TODO: This function is messy. Do something about it.

    # Generate the VPR tile grid
    new_tile_grid = {}
    for loc, tile in tile_grid.items():

        # Limit the grid range
        if not is_loc_within_limit(loc, grid_limit):
            continue

        tile_type = tile_types[tile.type]

        # Insert synthetic tiles in place of tiles that contain a BIDIR cell.
        if "BIDIR" in tile_type.type:
            new_tile_grid[loc] = Tile(
                type = "SYN_IO",
                name = tile.name
            )
            continue
 
        # FIXME: For now keep only tile that contains only one LOGIC cell inside
        if len(tile_type.cells) == 1 and list(tile_type.cells.keys())[0] == "LOGIC":
            new_tile_grid[loc] = tile

    # Extend the grid by 1 in every direction. Fill missing locs with empty
    # tiles.
    vpr_tile_grid = {}

    xs = [loc.x for loc in new_tile_grid.keys()]
    ys = [loc.y for loc in new_tile_grid.keys()]
    
    grid_min = Loc(min(xs), min(ys))
    grid_max = Loc(max(xs), max(ys))
    
    for x, y in itertools.product(range(grid_min[0], grid_max[0]+3),
                                  range(grid_min[1], grid_max[1]+3)):
        vpr_tile_grid[Loc(x=x,y=y)] = None

    # Populate tiles, build location maps
    fwd_loc_map = {}
    bwd_loc_map = {}

    for loc, tile in new_tile_grid.items():
        new_loc = Loc(loc.x+1, loc.y+1)
        vpr_tile_grid[new_loc] = tile

        fwd_loc_map[loc] = new_loc
        bwd_loc_map[new_loc] = loc

    return vpr_tile_grid, LocMap(fwd=fwd_loc_map, bwd=bwd_loc_map),

# =============================================================================


def process_switchbox_grid(phy_switchbox_grid, loc_map, grid_limit=None):
    """
    Processes the switchbox grid
    """

    # Remap locations
    vpr_switchbox_grid = {}
    for loc, switchbox_type in phy_switchbox_grid.items():

        if loc not in loc_map.fwd:
            continue

        new_loc = loc_map.fwd[loc]
        vpr_switchbox_grid[new_loc] = switchbox_type

    return vpr_switchbox_grid

# =============================================================================


def process_connections(phy_connections, loc_map, grid_limit=None):
    """
    Process the connection list.
    """

    # Pin map
    pin_map = {
        "BIDIR0_IZ":  "SYN_PAD0_O",
        "BIDIR0_OQI": "SYN_PAD0_I",
    }

    # Remap locations, remap pins
    vpr_connections = []
    for connection in phy_connections:

        # Reject connections that reach outsite the grid limit
        if not is_loc_within_limit(connection.src.loc, grid_limit):
            continue
        if not is_loc_within_limit(connection.dst.loc, grid_limit):
            continue

        # Remap source and destination coordinates
        src_loc = connection.src.loc
        dst_loc = connection.dst.loc

        if src_loc not in loc_map.fwd:
            continue
        if dst_loc not in loc_map.fwd:
            continue

        # Remap pins or discard the connection
        src_pin = connection.src.pin
        dst_pin = connection.dst.pin

        if src_pin in pin_map:
            src_pin = pin_map[src_pin]

        if dst_pin in pin_map:
            dst_pin = pin_map[dst_pin]

        if src_pin is None or dst_pin is None:
            continue

        # Add the new connection
        new_connection = Connection(
            src=ConnectionLoc(
                loc=loc_map.fwd[src_loc],
                pin=src_pin,
                is_direct=connection.src.is_direct,
            ),
            dst=ConnectionLoc(
                loc=loc_map.fwd[dst_loc],
                pin=dst_pin,
                is_direct=connection.dst.is_direct,
            ),
        )
        vpr_connections.append(new_connection)

    return vpr_connections

# =============================================================================


def main():
    
    # Parse arguments
    parser = argparse.ArgumentParser(description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter)

    parser.add_argument(
        "--phy-db",
        type=str,
        required=True,
        help="Input physical device database file"
    )
    parser.add_argument(
        "--vpr-db",
        type=str,
        default="vpr_database.pickle",
        help="Output VPR database file"
    )
    parser.add_argument(
        "--grid-limit",
        type=str,
        default=None,
        help="Grid coordinate range to import eg. '0,0,10,10' (def. None)"
    )

    args = parser.parse_args()

    # Grid limit
    if args.grid_limit is not None:
        grid_limit = [int(q) for q in args.grid_limit.split(",")]
    else:
        grid_limit = None

    # Load data from the database
    with open(args.phy_db, "rb") as fp:
        db = pickle.load(fp)

        cells_library  = db["cells_library"]
        tile_types     = db["tile_types"]
        phy_tile_grid  = db["phy_tile_grid"]
        switchbox_types= db["switchbox_types"]
        phy_switchbox_grid = db["switchbox_grid"]
        connections    = db["connections"]

    # Add synthetic stuff
    add_synthetic_cell_and_tile_types(tile_types, cells_library)

    # Process the tilegrid
    vpr_tile_grid, loc_map = process_tilegrid(tile_types, phy_tile_grid, grid_limit)

    # Process the switchbox grid
    vpr_switchbox_grid = process_switchbox_grid(phy_switchbox_grid, loc_map, grid_limit)

    # Process connections
    connections = process_connections(connections, loc_map, grid_limit)

    # Get tile types present in the grid
    vpr_tile_types = set([t.type for t in vpr_tile_grid.values() if t is not None])
    vpr_tile_types = {k: v for k, v in tile_types.items() if k in vpr_tile_types}

    # Get the switchbox types present in the grid
    vpr_switchbox_types = set([s for s in vpr_switchbox_grid.values() if s is not None])
    vpr_switchbox_types = {k: v for k, v in switchbox_types.items() if k in vpr_switchbox_types}

    # Prepare the VPR database and write it
    db_root = {
        "cells_library":  cells_library,
        "vpr_tile_types": vpr_tile_types,
        "vpr_tile_grid":  vpr_tile_grid,
        "vpr_switchbox_types": vpr_switchbox_types,
        "vpr_switchbox_grid":  vpr_switchbox_grid,
        "connections":    connections,
    }

    with open(args.vpr_db, "wb") as fp:
        pickle.dump(db_root, fp, protocol=3)

# =============================================================================


if __name__ == "__main__":
    main()
