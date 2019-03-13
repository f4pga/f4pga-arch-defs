import argparse
import prjxray.db
from prjxray.roi import Roi
import simplejson as json


def main():
    parser = argparse.ArgumentParser(description="Generate synth_tiles.json")
    parser.add_argument(
            '--db_root', required=True)
    parser.add_argument(
            '--db_overlay', help='Project X-Ray Database overlay path', required=False, default=None, type=str)
    parser.add_argument(
            '--roi', required=True)
    parser.add_argument(
            '--synth_tiles', required=False)

    args = parser.parse_args()

    if args.db_overlay:
        import db_overlay.db_overlay
        db = db_overlay.db_overlay.DatabaseWithOverlay(args.db_root, args.db_overlay)
    else:
        db = prjxray.db.Database(args.db_overlay)

    g = db.grid()

    synth_tiles = {}
    synth_tiles['tiles'] = {}

    with open(args.roi) as f:
        j = json.load(f)

    if args.db_overlay:
        import db_overlay.roi_overlay
        roi = db_overlay.roi_overlay.RoiWithOverlay(
                db=db,
                x1=j['info']['GRID_X_MIN'],
                y1=j['info']['GRID_Y_MIN'],
                x2=j['info']['GRID_X_MAX'],
                y2=j['info']['GRID_Y_MAX'],
                )

    else:
        roi = Roi(
                db=db,
                x1=j['info']['GRID_X_MIN'],
                y1=j['info']['GRID_Y_MIN'],
                x2=j['info']['GRID_X_MAX'],
                y2=j['info']['GRID_Y_MAX'],
                )

    synth_tiles['info'] = j['info']
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

        # Make sure connecting wire is not in ROI!
        loc = g.loc_of_tilename(tile)
        if roi.tile_in_roi(loc):
            # Or if in the ROI, make sure it has no sites.
            gridinfo = g.gridinfo_at_tilename(tile)
            assert len(db.get_tile_type(gridinfo.tile_type).get_sites()) == 0, tile

        if tile not in synth_tiles['tiles']:
            synth_tiles['tiles'][tile] = {
                    'pins': [],
                    'loc': g.loc_of_tilename(tile),
            }

        synth_tiles['tiles'][tile]['pins'].append({
                'roi_name': port['name'].replace('[', '_').replace(']','_'),
                'wire': wire,
                'pad': port['pin'],
                'port_type': port_type,
                'is_clock': is_clock,
        })

    with open(args.synth_tiles, 'w') as f:
        json.dump(synth_tiles, f)

if __name__ == "__main__":
    main()
