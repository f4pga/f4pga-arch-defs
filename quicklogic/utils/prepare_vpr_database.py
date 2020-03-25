#!/usr/bin/env python3
import argparse
import pickle
import itertools
import re

from data_structs import *
from utils import yield_muxes

from timing import compute_switchbox_timing_model
from timing import populate_switchbox_timing, copy_switchbox_timing

# =============================================================================

# IO cell types to ignore. They do not correspond to routable IO pads.
IGNORED_IO_CELL_TYPES = (
    "VCC",
    "GND",
)

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

    # The synthetic IO tile.
    tile_type = TileType("SYN_IO", {"BIDIR": 1})
    tile_type.make_pins(cells_library)
    tile_types[tile_type.type] = tile_type

    # Add a synthetic tile types for the VCC and GND const sources.
    # Models of the VCC and GND cells are already there in the cells_library.
    for const in ["VCC", "GND"]:
        tile_type = TileType("SYN_{}".format(const), {const: 1})
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

        # For a tile that contains at least one BIDIR cell make a new tile
        # just for that cell.
        if "BIDIR" in tile_type.type:
            new_tile_grid[loc] = Tile(
                type="SYN_IO",
                name=tile.name,
                cells=[
                    Cell(
                        type="BIDIR",
                        index=0,
                        name="BIDIR",
                        alias=None
                    )
                ]
            )
            continue

        # FIXME: For now keep only tile that contains only one LOGIC cell inside
        if len(tile_type.cells) == 1 and list(tile_type.cells.keys()
                                              )[0] == "LOGIC":
            new_tile_grid[loc] = tile

    # Find the ASSP tile. There are multiple tiles that contain the ASSP cell
    # but in fact there is only one ASSP cell for the whole FPGA which is
    # "distributed" along top and left edge of the grid.
    if "ASSP" in tile_types:

        # Place the ASSP tile
        assp_loc = Loc(x=0, y=0)
        if assp_loc in new_tile_grid:
            assert new_tile_grid[assp_loc] is None, ("ASSP", assp_loc)

        new_tile_grid[assp_loc] = Tile(
            type="ASSP", name="ASSP", cells=[
                Cell(
                    type="ASSP",
                    index=0,
                    name="ASSP",
                    alias=None
                )
            ]
        )

    # Insert synthetic VCC and GND source tiles.
    # FIXME: This assumes that the locations specified are empty!
    for const, loc in [("VCC", Loc(x=1, y=0)), ("GND", Loc(x=2, y=0))]:

        # Verify that the location is empty
        if loc in new_tile_grid:
            assert net_tile_grid[loc] is None, (const, loc)

        # Add the tile instance
        name = "SYN_{}".format(const)
        new_tile_grid[loc] = Tile(
            type=name, name=name, cells= [
                Cell(
                    type=const,
                    index=0,
                    name=const,
                    alias=None
                )
            ]
        )

    # Extend the grid by 1 in every direction. Fill missing locs with empty
    # tiles.
    vpr_tile_grid = {}

    xs = [loc.x for loc in new_tile_grid.keys()]
    ys = [loc.y for loc in new_tile_grid.keys()]

    grid_min = Loc(min(xs), min(ys))
    grid_max = Loc(max(xs), max(ys))

    for x, y in itertools.product(range(grid_min[0], grid_max[0] + 3),
                                  range(grid_min[1], grid_max[1] + 3)):
        vpr_tile_grid[Loc(x=x, y=y)] = None

    # Build tile map
    fwd_loc_map = {}
    bwd_loc_map = {}

    for x, y in itertools.product(range(grid_min[0], grid_max[0] + 1),
                                  range(grid_min[1], grid_max[1] + 1)):
        loc = Loc(x=x, y=y)
        new_loc = Loc(x=loc.x + 1, y=loc.y + 1)

        fwd_loc_map[loc] = new_loc
        bwd_loc_map[new_loc] = loc

    # Populate tiles
    for loc, tile in new_tile_grid.items():
        new_loc = fwd_loc_map[loc]
        assert vpr_tile_grid[new_loc] is None, (loc, new_loc, tile.type)
        vpr_tile_grid[new_loc] = tile

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


def process_connections(
        phy_connections, loc_map, vpr_tile_grid, grid_limit=None
):
    """
    Process the connection list.
    """

    # Pin map
    pin_map = {}

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
                type=connection.src.type,
            ),
            dst=ConnectionLoc(
                loc=loc_map.fwd[dst_loc],
                pin=dst_pin,
                type=connection.dst.type,
            ),
        )
        vpr_connections.append(new_connection)

    # Find locations of "special" tiles
    special_tile_loc = {"ASSP": None}

    for loc, tile in vpr_tile_grid.items():
        if tile is not None and tile.type in special_tile_loc:
            assert special_tile_loc[tile.type] is None, tile
            special_tile_loc[tile.type] = loc

    # Map connections going to/from them to their locations in the VPR grid
    for i, connection in enumerate(vpr_connections):

        # Process connection endpoints
        eps = [connection.src, connection.dst]
        for j, ep in enumerate(eps):

            if ep.type != ConnectionType.TILE:
                continue

            cell_name, pin = ep.pin.split("_", maxsplit=1)
            cell_type = cell_name[:-1
                                  ]  # FIXME: Will fail on cell with index >= 10

            if cell_type in special_tile_loc:
                loc = special_tile_loc[cell_type]

                eps[j] = ConnectionLoc(
                    loc=loc,
                    pin=ep.pin,
                    type=ep.type,
                )

        # Modify the connection
        vpr_connections[i] = Connection(src=eps[0], dst=eps[1])

    return vpr_connections


# =============================================================================


def get_cell_type_by_name_at_loc(loc, cell_name, tile_grid):
    """
    Returns type of a cell with the given name at the given loc. Returns None
    if the cell cannot be found.
    """

    if loc not in tile_grid:
        return None

    tile = tile_grid[loc]
    if tile is None:
        return None

    # Find cell
    for cell in tile.cells:
        if cell_name in cell.name:
            return cell.type

    return None


def process_package_pinmap(package_pinmap, phy_tile_grid, loc_map):
    """
    Processes the package pinmap. Reloacted pin mappings. Reject mappings
    that lie outside the grid limit.
    """

    # Remap locations
    new_package_pinmap = {}
    for pin_name, pin in package_pinmap.items():

        # The loc is outside the grid limit, skip it.
        if pin.loc not in loc_map.fwd:
            continue

        # Process cells. Look for cells from the ignore list and remove them
        cell_names = []
        for cell_name in pin.cell_names:

            cell_type = get_cell_type_by_name_at_loc(
                pin.loc, cell_name, phy_tile_grid
            )
            assert cell_type is not None, (pin.name, cell_name, pin.loc)

            if cell_type not in IGNORED_IO_CELL_TYPES:
                cell_names.append(cell_name)

        # No cells for that pin, skip it
        if len(cell_names) == 0:
            continue

        # Remap location
        new_loc = loc_map.fwd[pin.loc]

        new_package_pinmap[pin_name] = PackagePin(
            name=pin.name,
            loc=new_loc,
            cell_names=cell_names  # TODO: Should probably map cell names here
        )

    return new_package_pinmap


# =============================================================================


def build_switch_list():
    """
    Builds a list of all switch types used by the architecture
    """
    switches = {}

    # Add a generic mux switch to make VPR happy
    switch = VprSwitch(
        name="generic",
        type="mux",
        t_del=0.0,
        r=0.0,
        c_in=0.0,
        c_out=0.0,
        c_int=0.0,
    )
    switches[switch.name] = switch

    # A delayless short
    switch = VprSwitch(
        name="short",
        type="short",
        t_del=0.0,
        r=0.0,
        c_in=0.0,
        c_out=0.0,
        c_int=0.0,
    )
    switches[switch.name] = switch

    return switches


def build_segment_list():
    """
    Builds a list of all segment types used by the architecture
    """
    segments = {}

    # A generic segment
    segment = VprSegment(
        name="generic",
        length=1,
        r_metal=0.0,
        c_metal=0.0,
    )
    segments[segment.name] = segment

    # Padding segment
    segment = VprSegment(
        name="pad",
        length=1,
        r_metal=0.0,
        c_metal=0.0,
    )
    segments[segment.name] = segment

    # Switchbox segment
    segment = VprSegment(
        name="sbox",
        length=1,
        r_metal=0.0,
        c_metal=0.0,
    )
    segments[segment.name] = segment

    # VCC and GND segments
    for const in ["VCC", "GND"]:
        segment = VprSegment(
            name=const.lower(),
            length=1,
            r_metal=0.0,
            c_metal=0.0,
        )
        segments[segment.name] = segment

    # HOP wire segments
    for i in [1, 2, 3, 4]:
        segment = VprSegment(
            name="hop{}".format(i),
            length=i,
            r_metal=0.0,
            c_metal=0.0,
        )
        segments[segment.name] = segment

    # A segment for "hop" connections to "special" tiles.
    segment = VprSegment(
        name="special",
        length=1,
        r_metal=0.0,
        c_metal=0.0,
    )
    segments[segment.name] = segment

    return segments


# =============================================================================


def main():

    # Parse arguments
    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter
    )

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

        cells_library = db["cells_library"]
        tile_types = db["tile_types"]
        phy_tile_grid = db["phy_tile_grid"]
        switchbox_types = db["switchbox_types"]
        phy_switchbox_grid = db["switchbox_grid"]
        switchbox_timing = db["switchbox_timing"]
        connections = db["connections"]
        package_pinmaps = db["package_pinmaps"]

    # Add synthetic stuff
    add_synthetic_cell_and_tile_types(tile_types, cells_library)

    # Process the tilegrid
    vpr_tile_grid, loc_map = process_tilegrid(
        tile_types, phy_tile_grid, grid_limit
    )

    # Process the switchbox grid
    vpr_switchbox_grid = process_switchbox_grid(
        phy_switchbox_grid, loc_map, grid_limit
    )

    # Process connections
    connections = process_connections(
        connections, loc_map, vpr_tile_grid, grid_limit
    )

    # Process package pinmaps
    vpr_package_pinmaps = {}
    for package, pkg_pin_map in package_pinmaps.items():
        vpr_package_pinmaps[package] = process_package_pinmap(
            pkg_pin_map, phy_tile_grid, loc_map
        )

    # Get tile types present in the grid
    vpr_tile_types = set(
        [t.type for t in vpr_tile_grid.values() if t is not None]
    )
    vpr_tile_types = {
        k: v
        for k, v in tile_types.items()
        if k in vpr_tile_types
    }

    # Get the switchbox types present in the grid
    vpr_switchbox_types = set(
        [s for s in vpr_switchbox_grid.values() if s is not None]
    )
    vpr_switchbox_types = {
        k: v
        for k, v in switchbox_types.items()
        if k in vpr_switchbox_types
    }

    # Make switch list
    vpr_switches = build_switch_list()
    # Make segment list
    vpr_segments = build_segment_list()

    # Process timing data
    if switchbox_timing is not None:
        print("Processing timing data...")

        # The timing data seems to be the same for each switchbox type and is
        # stored under the SB_LC name.
        timing_data = switchbox_timing["SB_LC"]

        # Compute the timing model for the most generic SB_LC switchbox.
        switchbox = vpr_switchbox_types["SB_LC"]
        driver_timing, sink_map = compute_switchbox_timing_model(
            switchbox, timing_data
        )

        # Populate the model, create and assign VPR switches.
        populate_switchbox_timing(
            switchbox, driver_timing, sink_map, vpr_switches
        )

        # Propagate the timing data to all other switchboxes. Even though they
        # are of different type, physically they are the same.
        for dst_switchbox in vpr_switchbox_types.values():
            if dst_switchbox.type != "SB_LC":
                copy_switchbox_timing(switchbox, dst_switchbox)

    # DEBUG
    print("VPR Segments:")
    for s in vpr_segments.values():
        print("", s)

    # DEBUG
    print("VPR Switches:")
    for s in vpr_switches.values():
        print("", s)

    # Prepare the VPR database and write it
    db_root = {
        "cells_library": cells_library,
        "loc_map": loc_map,
        "vpr_tile_types": vpr_tile_types,
        "vpr_tile_grid": vpr_tile_grid,
        "vpr_switchbox_types": vpr_switchbox_types,
        "vpr_switchbox_grid": vpr_switchbox_grid,
        "connections": connections,
        "vpr_package_pinmaps": vpr_package_pinmaps,
        "segments": list(vpr_segments.values()),
        "switches": list(vpr_switches.values()),
    }

    with open(args.vpr_db, "wb") as fp:
        pickle.dump(db_root, fp, protocol=3)


# =============================================================================

if __name__ == "__main__":
    main()
