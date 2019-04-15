import argparse
import prjxray.db
from prjxray.roi import Roi
import simplejson as json

from prjxray.grid_types import GridLoc

from prjxray_db_cache import DatabaseCache
from lib.grid_mapping import GridLocMap


def find_vbrk_closest_to(grid, roi, loc, loc_in_use):
    """
    Finds a VBRK tile (optionally within the ROI) which is located closest
    to a given location. Checks if such a tile is not already used by
    another synth tile.

    Args:
        grid: A Grid object from the prjxray database
        roi: A Roi object from the prjxray database or None when ROI not used.
        loc: A GridLoc with location to find the closest VBRK to.
        loc_in_use: A set with GridLoc objects which indicate occupied VBRKs

    Returns:
        A GridLoc with the "best" (closest) VBRK tile location to the given
        input loc.
    """

    loc_best = None
    min_cost = None

    for tile in grid.tiles():
        tile_loc = grid.loc_of_tilename(tile)

        # Not a VBRK
        gridinfo = grid.gridinfo_at_tilename(tile)
        if 'VBRK' not in gridinfo.tile_type:
            continue

        # Already used
        if tile_loc in loc_in_use:
            continue

        # Not in ROI
        if roi is not None:
            if not roi.tile_in_roi(tile_loc):
                continue

        # Get distance
        #cost = abs(tile_loc.grid_x - loc.grid_x) + \
        #       abs(tile_loc.grid_y - loc.grid_y)
        cost = (tile_loc.grid_x - loc.grid_x) ** 2 + \
               (tile_loc.grid_y - loc.grid_y) ** 2

        # Find best
        if min_cost is None or cost < min_cost:
            min_cost = cost
            loc_best = GridLoc(tile_loc.grid_x, tile_loc.grid_y)

    return loc_best


def main():
    parser = argparse.ArgumentParser(description="Generate synth_tiles.json")
    parser.add_argument('--db_root', required=True)
    parser.add_argument('--roi', required=True)
    parser.add_argument(
        '--connection_database', help='Connection database', required=True
    )
    parser.add_argument('--synth_tiles', required=False)

    args = parser.parse_args()

    db = prjxray.db.Database(args.db_root)
    g = db.grid()

    synth_tiles = {}
    synth_tiles['tiles'] = {}

    # Initialize grid mapper
    with DatabaseCache(args.connection_database, read_only=True) as conn:

        # The object will read data from the DB so it can live
        # outside the scope of the "with" statement
        grid_loc_mapper = GridLocMap.load_from_database(conn)

    with open(args.roi) as f:
        j = json.load(f)

    roi = Roi(
        db=db,
        x1=j['info']['GRID_X_MIN'],
        y1=j['info']['GRID_Y_MIN'],
        x2=j['info']['GRID_X_MAX'],
        y2=j['info']['GRID_Y_MAX'],
    )

    # Map ROI coordinates to the target VPR grid
    roi_loc_lo = grid_loc_mapper.get_vpr_loc(
        (j['info']['GRID_X_MIN'], j['info']['GRID_Y_MIN'])
    )
    roi_loc_hi = grid_loc_mapper.get_vpr_loc(
        (j['info']['GRID_X_MAX'], j['info']['GRID_Y_MAX'])
    )

    synth_tiles['info'] = {
        "GRID_X_MIN": min([p[0] for p in roi_loc_lo]),
        "GRID_Y_MIN": min([p[1] for p in roi_loc_lo]),
        "GRID_X_MAX": max([p[0] for p in roi_loc_hi]),
        "GRID_Y_MAX": max([p[1] for p in roi_loc_hi])
    }

    vbrk_loc_in_use = set()

    for port in j['ports']:
        if port['name'].startswith('dout['):
            port_type = 'input'
            is_clock = False
        elif port['name'].startswith('din['):
            is_clock = False
            port_type = 'output'
        elif port['name'].startswith('clk'):
            port_type = 'output'
            is_clock = True
        else:
            assert False, port

        tile, wire = port['wire'].split('/')
        loc = g.loc_of_tilename(tile)

        # Mark location as used by a synth tile
        assert loc not in vbrk_loc_in_use
        vbrk_loc_in_use.add(loc)

        # Map tile location to the VPR grid
        vpr_loc = grid_loc_mapper.get_vpr_loc((loc.grid_x, loc.grid_y))
        vpr_loc = vpr_loc[0]  # FIXME: Assuming no split of that tile!
        vpr_loc = GridLoc(vpr_loc[0], vpr_loc[1])

        # Make sure connecting wire is not in ROI!
        if roi.tile_in_roi(loc):
            # Or if in the ROI, make sure it has no sites.
            gridinfo = g.gridinfo_at_tilename(tile)
            assert len(
                db.get_tile_type(gridinfo.tile_type).get_sites()
            ) == 0, tile

        if tile not in synth_tiles['tiles']:
            synth_tiles['tiles'][tile] = {
                'pins': [],
                'loc': vpr_loc,
            }

        synth_tiles['tiles'][tile]['pins'].append(
            {
                'roi_name': port['name'].replace('[', '_').replace(']', '_'),
                'wire': wire,
                'pad': port['pin'],
                'port_type': port_type,
                'is_clock': is_clock,
            }
        )

    # Find two VBRK's in the corner of the fabric to use as the synthetic VCC
    loc_min = GridLoc(g.dims()[0], g.dims()[2])
    loc_max = GridLoc(g.dims()[0], g.dims()[3])

    #print("loc_min:", loc_min, "phy")
    #print("loc_max:", loc_max, "phy")

    vcc_loc = find_vbrk_closest_to(g, roi, loc_min, vbrk_loc_in_use)
    vbrk_loc_in_use.add(vcc_loc)

    gnd_loc = find_vbrk_closest_to(g, roi, loc_max, vbrk_loc_in_use)
    vbrk_loc_in_use.add(gnd_loc)

    # Get tiles
    vcc_tile = g.tilename_at_loc(vcc_loc)
    gnd_tile = g.tilename_at_loc(gnd_loc)

    #print("VCC at:", vcc_loc, "phy")
    #print("GND at:", gnd_loc, "phy")

    # Map those locations to the VPR grid
    vcc_loc = grid_loc_mapper.get_vpr_loc((vcc_loc.grid_x, vcc_loc.grid_y))
    vcc_loc = vcc_loc[0]
    vcc_loc = GridLoc(vcc_loc[0], vcc_loc[1])

    gnd_loc = grid_loc_mapper.get_vpr_loc((gnd_loc.grid_x, gnd_loc.grid_y))
    gnd_loc = gnd_loc[0]
    gnd_loc = GridLoc(gnd_loc[0], gnd_loc[1])

    #print("VCC at:", vcc_loc, "vpr")
    #print("GND at:", gnd_loc, "vpr")

    # Insert tiles
    synth_tiles['tiles'][vcc_tile] = {
        'loc':
            vcc_loc,
        'pins':
            [
                {
                    'wire': 'VCC',
                    'pad': 'VCC',
                    'port_type': 'VCC',
                    'is_clock': False,
                },
            ],
    }

    synth_tiles['tiles'][gnd_tile] = {
        'loc':
            gnd_loc,
        'pins':
            [
                {
                    'wire': 'GND',
                    'pad': 'GND',
                    'port_type': 'GND',
                    'is_clock': False,
                },
            ],
    }

    # Save it
    with open(args.synth_tiles, 'w') as f:
        json.dump(synth_tiles, f, indent=2)


if __name__ == "__main__":
    main()
