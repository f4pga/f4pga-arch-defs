import argparse
import prjxray.db
from prjxray.roi import Roi
import simplejson as json

from prjxray_db_cache import DatabaseCache


def map_tile_to_vpr_coord(conn, tile):
    """ Converts prjxray tile name into VPR tile coordinates.

    It is assumed that this tile should only have one mapped tile.

    """
    c = conn.cursor()
    c.execute("SELECT pkey FROM phy_tile WHERE name = ?;", (tile, ))
    phy_tile_pkey = c.fetchone()[0]

    c.execute("SELECT pkey FROM tile_type WHERE name = 'NULL'")
    null_tile_type_pkey, = c.fetchone()

    # It is expected that this tile has only one logical location,
    # because why split a tile with no sites?
    c.execute(
        """
SELECT tile_map.tile_pkey FROM tile_map INNER JOIN tile
ON tile_map.tile_pkey = tile.pkey INNER JOIN tile_type
ON tile.tile_type_pkey = tile_type.pkey
WHERE tile_map.phy_tile_pkey = ? AND tile_type.name != 'NULL'
    """, (phy_tile_pkey, )
    )
    mapped_tiles = c.fetchall()
    assert len(mapped_tiles) == 1, tile
    tile_pkey = mapped_tiles[0][0]

    c.execute("SELECT grid_x, grid_y FROM tile WHERE pkey = ?", (tile_pkey, ))
    grid_x, grid_y = c.fetchone()

    return grid_x, grid_y


def main():
    parser = argparse.ArgumentParser(description="Generate synth_tiles.json")
    parser.add_argument('--db_root', required=True)
    parser.add_argument('--part', required=True)
    parser.add_argument('--roi', required=True)
    parser.add_argument(
        '--connection_database', help='Connection database', required=True
    )
    parser.add_argument('--synth_tiles', required=True)

    args = parser.parse_args()

    db = prjxray.db.Database(args.db_root, args.part)
    g = db.grid()

    synth_tiles = {}
    synth_tiles['tiles'] = {}

    with open(args.roi) as f:
        j = json.load(f)

    roi = Roi(
        db=db,
        x1=j['info']['GRID_X_MIN'],
        y1=j['info']['GRID_Y_MIN'],
        x2=j['info']['GRID_X_MAX'],
        y2=j['info']['GRID_Y_MAX'],
    )

    with DatabaseCache(args.connection_database, read_only=True) as conn:
        synth_tiles['info'] = j['info']
        vbrk_in_use = set()
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

            # Make sure connecting wire is not in ROI!
            loc = g.loc_of_tilename(tile)
            if roi.tile_in_roi(loc):
                # Or if in the ROI, make sure it has no sites.
                gridinfo = g.gridinfo_at_tilename(tile)
                assert len(
                    db.get_tile_type(gridinfo.tile_type).get_sites()
                ) == 0, tile

            vpr_loc = map_tile_to_vpr_coord(conn, tile)

            if tile not in synth_tiles['tiles']:
                synth_tiles['tiles'][tile] = {
                    'pins': [],
                    'loc': vpr_loc,
                }

            synth_tiles['tiles'][tile]['pins'].append(
                {
                    'roi_name':
                        port['name'].replace('[', '_').replace(']', '_'),
                    'wire':
                        wire,
                    'pad':
                        port['pin'],
                    'port_type':
                        port_type,
                    'is_clock':
                        is_clock,
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

            assert len(
                db.get_tile_type(gridinfo.tile_type).get_sites()
            ) == 0, tile

            if vbrk_loc is None:
                vbrk2_loc = vbrk_loc
                vbrk2_tile = vbrk_tile
                vbrk_loc = loc
                vbrk_tile = tile
            else:
                if (loc.grid_x < vbrk_loc.grid_x
                        and loc.grid_y < vbrk_loc.grid_y) or vbrk2_loc is None:
                    vbrk2_loc = vbrk_loc
                    vbrk2_tile = vbrk_tile
                    vbrk_loc = loc
                    vbrk_tile = tile

        assert vbrk_loc is not None
        assert vbrk_tile is not None
        assert vbrk_tile not in synth_tiles['tiles']

        vbrk_vpr_loc = map_tile_to_vpr_coord(conn, vbrk_tile)
        synth_tiles['tiles'][vbrk_tile] = {
            'loc':
                vbrk_vpr_loc,
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
        vbrk2_vpr_loc = map_tile_to_vpr_coord(conn, vbrk2_tile)
        synth_tiles['tiles'][vbrk2_tile] = {
            'loc':
                vbrk2_vpr_loc,
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
