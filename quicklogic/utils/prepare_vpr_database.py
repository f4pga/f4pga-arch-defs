#!/usr/bin/env python3
import argparse
import pickle

from data_structs import *

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

    # Generate the VPR tile grid
    new_tile_grid = {}
    for loc, tile in tile_grid.items():

        # Limit the grid range
        if grid_limit is not None:
            if loc.x < grid_limit[0] or loc.x > grid_limit[2]:
                continue
            if loc.y < grid_limit[1] or loc.y > grid_limit[3]:
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

    return new_tile_grid

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
        default="db_vpr.pickle",
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

        cells_library = db["cells_library"]
        tile_types    = db["tile_types"]
        phy_tile_grid = db["phy_tile_grid"]

    # Add synthetic stuff
    add_synthetic_cell_and_tile_types(tile_types, cells_library)
    # Process the tilegrid
    vpr_tile_grid = process_tilegrid(tile_types, phy_tile_grid, grid_limit)

    # Get tile types present in the grid
    vpr_tile_types = set([t.type for t in vpr_tile_grid.values()])
    vpr_tile_types = {k: v for k, v in tile_types.items() if k in vpr_tile_types}

    # Prepare the VPR database and write it
    db_root = {
        "cells_library":  cells_library,
        "vpr_tile_types": vpr_tile_types,
        "vpr_tile_grid":  vpr_tile_grid,
    }

    with open(args.vpr_db, "wb") as fp:
        pickle.dump(db_root, fp, protocol=3)

# =============================================================================


if __name__ == "__main__":
    main()
