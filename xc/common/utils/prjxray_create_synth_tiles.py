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

    # Filters NULL tiles to prevent selecting two tiles that point
    # to the same phy_tile
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


def tile_in_roi(conn, g, roi, tile_pkey):
    """
    Checks if the given tile_pkey is at a location within the specified roi
    """
    c = conn.cursor()
    c.execute(
        """
SELECT name FROM phy_tile WHERE pkey =
(SELECT phy_tile_pkey FROM tile WHERE pkey = ?)
""", (tile_pkey, )
    )
    tile, = c.fetchone()
    loc = g.loc_of_tilename(tile)
    return roi.tile_in_roi(loc)


def wire_in_roi(conn, g, roi, wire_pkey):
    """
    Checks if the given wire_pkey is at a location within the specified roi
    """
    c = conn.cursor()
    c.execute("""
SELECT tile_pkey FROM wire WHERE pkey = ?
""", (wire_pkey, ))
    tile_pkey, = c.fetchone()
    return tile_in_roi(conn, g, roi, tile_pkey)


def wire_manhattan_distance(conn, wire_pkey1, wire_pkey2):
    """
    Determines the manhattan distance between two tiles containing
    the given wire_pkeys
    """
    c = conn.cursor()
    c.execute(
        """
SELECT grid_x, grid_y FROM tile WHERE pkey = (SELECT tile_pkey FROM wire WHERE pkey = ?)
""", (wire_pkey1, )
    )
    x1, y1 = c.fetchone()
    c.execute(
        """
SELECT grid_x, grid_y FROM tile WHERE pkey = (SELECT tile_pkey FROM wire WHERE pkey = ?)
""", (wire_pkey2, )
    )
    x2, y2 = c.fetchone()
    return abs(x1 - x2) + abs(y1 - y2)


def find_wire_from_node(conn, g, roi, node_name):
    """
    Finds a pair on wires in the given node such that:
    1. One wire is inside the roi and the other is outside
    2. The manhattan distance between these the wires is the minimum of any such pair

    Returns the wire from this pair that is outside the roi and the tile the returned
    wire is contained in.
    """
    tile, node = node_name.split('/')

    cur = conn.cursor()
    cur.execute(
        """
SELECT pkey, node_pkey FROM wire WHERE
wire_in_tile_pkey IN (SELECT pkey FROM wire_in_tile WHERE name = ?)
AND
phy_tile_pkey = (SELECT pkey FROM phy_tile WHERE name = ?)
    """, (node, tile)
    )
    results = cur.fetchall()
    assert len(results) == 1
    wire_pkey, node_pkey = results[0]
    cur.execute(
        """
SELECT pkey FROM wire WHERE node_pkey = ?
""", (node_pkey, )
    )
    wire_pkeys = cur.fetchall()
    in_outs = {w: (overlay ^ wire_in_roi(conn, g, roi, w)) for w, in wire_pkeys}
    ins = {i for i, v in in_outs.items() if v}
    outs = {i for i, v in in_outs.items() if not v}
    min_manhattan_dist = 1000000
    for i in ins:
        for j in outs:
            d = wire_manhattan_distance(conn, i, j)
            if d < min_manhattan_dist:
                min_manhattan_dist = d
                correct_wire = j

    cur.execute(
        """
SELECT node_pkey, phy_tile_pkey, wire_in_tile_pkey FROM wire WHERE pkey = ?
""", (correct_wire, )
    )
    node_pkey_correct_wire, phy_tile_pkey, wire_in_tile_pkey = cur.fetchone()
    cur.execute(
        """
SELECT name, tile_type_pkey FROM wire_in_tile WHERE pkey = ?
""", (wire_in_tile_pkey, )
    )
    wire, tile_type_pkey = cur.fetchone()
    cur.execute(
        """
SELECT name FROM tile_type WHERE pkey = ?
""", (tile_type_pkey, )
    )
    tile_type, = cur.fetchone()
    cur.execute(
        """
SELECT name FROM phy_tile WHERE pkey = ?
""", (phy_tile_pkey, )
    )
    tile, = cur.fetchone()
    return tile, wire


def main():
    parser = argparse.ArgumentParser(description="Generate synth_tiles.json")
    parser.add_argument('--db_root', required=True)
    parser.add_argument('--part', required=True)
    parser.add_argument('--roi', required=False)
    parser.add_argument('--overlay', required=False)
    parser.add_argument(
        '--connection_database', help='Connection database', required=True
    )
    parser.add_argument('--synth_tiles', required=True)

    args = parser.parse_args()

    db = prjxray.db.Database(args.db_root, args.part)
    g = db.grid()

    synth_tiles = {}
    synth_tiles['tiles'] = {}
    synth_tiles['info'] = list()

    rois = dict()
    if args.roi:
        with open(args.roi) as f:
            j = json.load(f)

        
        roi = Roi(
            db=db,
            x1=j['info']['GRID_X_MIN'],
            y1=j['info']['GRID_Y_MIN'],
            x2=j['info']['GRID_X_MAX'],
            y2=j['info']['GRID_Y_MAX'],
        )

        rois[roi] = j
    elif args.overlay:
        with open(args.overlay) as f:
            j = json.load(f)
        
        for r in j:
            roi = Roi(
                db=db,
                x1=r['info']['GRID_X_MIN'],
                y1=r['info']['GRID_Y_MIN'],
                x2=r['info']['GRID_X_MAX'],
                y2=r['info']['GRID_Y_MAX'],
            )

            rois[roi] = r
    else:
        assert False, 'Synth tiles must be for roi or overlay'


    with DatabaseCache(args.connection_database, read_only=True) as conn:
        tile_in_use = set()
        for roi, j in rois.items():

            synth_tiles['info'].append(j['info'])
            tile_pin_count = dict()
            num_synth_tiles = 0
            for port in sorted(j["ports"], key=lambda i: i['name']):
                if port['type'] == 'out':
                    port_type = 'input' if not args.overlay else 'output'
                    is_clock = False
                elif port['type'] == 'in':
                    is_clock = False
                    port_type = 'output' if not args.overlay else 'input'
                elif port['type'] == 'clk':
                    port_type = 'output' if not args.overlay else 'input'
                    is_clock = True
                else:
                    assert False, port

                if 'wire' not in port:
                    tile, wire = find_wire_from_node(conn, g, roi, port['node'], overlay=bool(args.overlay))
                else:
                    tile, wire = port['wire'].split('/')

                tile_in_use.add(tile)

                # Make sure connecting wire is not in ROI!
                loc = g.loc_of_tilename(tile)

                if bool(args.overlay) ^ roi.tile_in_roi(loc):
                    # Or if in the ROI, make sure it has no sites.
                    gridinfo = g.gridinfo_at_tilename(tile)
                    assert len(db.get_tile_type(gridinfo.tile_type).get_sites()
                               ) == 0, "{}/{}".format(tile, wire)

                vpr_loc = map_tile_to_vpr_coord(conn, tile)

                if tile not in synth_tiles['tiles']:
                    tile_name = 'SYN-IOPAD-{}'.format(num_synth_tiles)
                    synth_tiles['tiles'][tile] = {
                        'pins': [],
                        'loc': vpr_loc,
                        'tile_name': tile_name,
                    }
                    num_synth_tiles += 1
                    tile_pin_count[tile] = 0

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
                        'z_loc':
                            tile_pin_count[tile],
                    }
                )

                tile_pin_count[tile] += 1

        if not args.overlay:
            # Find two VBRK's in the corner of the fabric to use as the synthetic VCC/
            # GND source.
            vbrk_loc = None
            vbrk_tile = None
            vbrk2_loc = None
            vbrk2_tile = None
            for tile in g.tiles():
                if tile in tile_in_use:
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
