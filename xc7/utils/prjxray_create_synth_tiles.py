import argparse
import prjxray.db
from prjxray.roi import Roi
import simplejson as json

from prjxray.grid_types import GridLoc

from prjxray_db_cache import DatabaseCache
from lib.grid_mapping import GridLocMap


def main():
    parser = argparse.ArgumentParser(description="Generate synth_tiles.json")
    parser.add_argument('--db_root', required=True)
    parser.add_argument('--roi', required=True)
    parser.add_argument(
        '--connection_database', help='Connection database', required=True)
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
        grid_loc_mapper = GridLocMap(conn)

    with open(args.roi) as f:
        j = json.load(f)

    # Map ROI coordinates to the target VPR grid
    roi_loc_lo = grid_loc_mapper.get_vpr_loc(
        (j['info']['GRID_X_MIN'], j['info']['GRID_Y_MIN']))
    roi_loc_hi = grid_loc_mapper.get_vpr_loc(
        (j['info']['GRID_X_MAX'], j['info']['GRID_Y_MAX']))

    vbrk_in_use = set()

    roi = Roi(
        db=db,
        x1=min([p[0] for p in roi_loc_lo
                ]),  # One physical grid location may map to more than one
        y1=min([p[1] for p in roi_loc_lo
                ]),  # VPR locations. So here we take min and max.
        x2=max([p[0] for p in roi_loc_hi]),
        y2=max([p[1] for p in roi_loc_hi]),
    )

    synth_tiles['info'] = {
        "GRID_X_MIN": roi.x1,
        "GRID_Y_MIN": roi.y1,
        "GRID_X_MAX": roi.x2,
        "GRID_Y_MAX": roi.y2
    }

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

        vbrk_in_use.add(tile)

        # Map tile location to the VPR grid
        loc = g.loc_of_tilename(tile)
        vpr_loc = grid_loc_mapper.get_vpr_loc((loc.grid_x, loc.grid_y))
        vpr_loc = vpr_loc[0]  # FIXME: Assuming no split of that tile!
        vpr_loc = GridLoc(vpr_loc[0], vpr_loc[1])

        # Make sure connecting wire is not in ROI!
        if roi.tile_in_roi(vpr_loc):
            # Or if in the ROI, make sure it has no sites.
            gridinfo = g.gridinfo_at_tilename(tile)
            assert len(
                db.get_tile_type(gridinfo.tile_type).get_sites()) == 0, tile

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

    # Find two VBRK's in the corner of the fabric to use as the synthetic VCC/
    # GND source.
    vbrk_loc = None
    vbrk_tile = None
    vbrk2_loc = None
    vbrk2_tile = None
    for tile in g.tiles():
        if tile in vbrk_in_use:
            continue

        loc = g.loc_of_tilename(tile)
        if not roi.tile_in_roi(loc):
            continue

        gridinfo = g.gridinfo_at_tilename(tile)
        if 'VBRK' not in gridinfo.tile_type:
            continue

        assert len(db.get_tile_type(gridinfo.tile_type).get_sites()) == 0, tile

        if vbrk_loc is None:
            vbrk2_loc = vbrk_loc
            vbrk2_tile = vbrk_tile
            vbrk_loc = loc
            vbrk_tile = tile
        else:
            if loc.grid_x < vbrk_loc.grid_x and loc.grid_y < vbrk_loc.grid_y or vbrk2_loc is None:
                vbrk2_loc = vbrk_loc
                vbrk2_tile = vbrk_tile
                vbrk_loc = loc
                vbrk_tile = tile

    assert vbrk_loc is not None
    assert vbrk_tile is not None
    assert vbrk_tile not in synth_tiles['tiles']
    synth_tiles['tiles'][vbrk_tile] = {
        'loc':
            vbrk_loc,
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

    assert vbrk2_loc is not None
    assert vbrk2_tile is not None
    assert vbrk2_tile not in synth_tiles['tiles']
    synth_tiles['tiles'][vbrk2_tile] = {
        'loc':
            vbrk2_loc,
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

    with open(args.synth_tiles, 'w') as f:
        json.dump(synth_tiles, f, indent=2)


if __name__ == "__main__":
    main()
