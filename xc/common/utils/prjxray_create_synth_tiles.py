import argparse
import prjxray.db
from lib.connection_database import (
    NodeClassification, yield_logical_wire_info_from_node, get_track_model,
    node_to_site_pins, get_pin_name_of_wire, yield_wire_info_from_node,
    get_wire_pkey
)
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
        "SELECT tile_pkey FROM tile_map WHERE phy_tile_pkey = ? AND tile_type_pkey != ?",
        (phy_tile_pkey, null_tile_type_pkey)
    )
    mapped_tiles = c.fetchone()
    print(mapped_tiles)
    tile_pkey, = mapped_tiles

    c.execute("SELECT grid_x, grid_y FROM tile WHERE pkey = ?", (tile_pkey, ))
    grid_x, grid_y = c.fetchone()

    return grid_x, grid_y


def graph_node_borders_region(conn, roi, graph_node_pkey):
    if graph_node_pkey is None:
        return False
    c = conn.cursor()
    print(graph_node_pkey)
    c.execute(
        """
SELECT x_low, x_high, y_low, y_high FROM graph_node WHERE pkey = ?
""", (graph_node_pkey, )
    )
    x_low, x_high, y_low, y_high = c.fetchone()
    x1 = roi.x1
    x2 = roi.x2
    y1 = roi.y1
    y2 = roi.y2
    print(x_low, x_high, y_low, y_high)
    return (x_high == x1-1 and x_low <= x1) or \
           (x_low == x2 and x_high >= x2) or \
           (y_high == y1 and y_low <= y1) or \
           (y_low == y2 and y_high >= y2)


def in_roi(roi, x, y):
    return x >= roi.x1 and x <= roi.x2 and y >= roi.y1 and y <= roi.y2


def tile_in_roi(conn, g, roi, tile_pkey):
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


#    return in_roi(roi, x, y)


def wire_in_roi(conn, g, roi, wire_pkey):
    c = conn.cursor()
    c.execute("""
SELECT tile_pkey FROM wire WHERE pkey = ?
""", (wire_pkey, ))
    tile_pkey, = c.fetchone()
    return tile_in_roi(conn, g, roi, tile_pkey)


def wires_colinear(conn, wire_pkey1, wire_pkey2):
    c1 = conn.cursor()
    c2 = conn.cursor()
    c1.execute(
        """
SELECT pkey FROM graph_node 
WHERE pkey = (SELECT node_pkey FROM wire WHERE pkey = ?)
""", (wire_pkey1, )
    )
    c2.execute(
        """
SELECT pkey FROM graph_node 
WHERE pkey = (SELECT node_pkey FROM wire WHERE pkey = ?)
""", (wire_pkey2, )
    )
    pkey1 = c1.fetchone()[0]
    pkey2 = c2.fetchone()[0]
    c3 = conn.cursor()
    c3.execute(
        """
SELECT COUNT (*) FROM graph_edge 
WHERE (src_graph_node_pkey = ? AND dest_graph_node_pkey = ?) OR
(src_graph_node_pkey = ? AND dest_graph_node_pkey = ?)
""", (pkey1, pkey2, pkey2, pkey1)
    )
    print(pkey1 == pkey2)
    if pkey1 == pkey2:
        return True
    num_graph_edges = c3.fetchone()
    print(num_graph_edges)
    print(pkey1 == pkey2)
    return pkey1 == pkey2 or num_graph_edges


def wire_manhattan_distance(conn, wire_pkey1, wire_pkey2):
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
    graph_node_pkeys = set()
    cur.execute(
        """
SELECT pkey FROM wire WHERE node_pkey = ?
""", (node_pkey, )
    )
    wire_pkeys = cur.fetchall()
    in_outs = {w: wire_in_roi(conn, g, roi, w) for w, in wire_pkeys}
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
    parser.add_argument(
        '--connection_database', help='Connection database', required=True
    )
    parser.add_argument('--partition_region', required=False)
    parser.add_argument('--synth_tiles', required=True)

    args = parser.parse_args()

    db = prjxray.db.Database(args.db_root, args.part)
    g = db.grid()

    synth_tiles = {}
    synth_tiles['tiles'] = {}

    if args.roi:
        with open(args.roi) as f:
            j = json.load(f)
    elif args.partition_region:
        with open(args.partition_region) as f:
            j = json.load(f)
    else:
        assert False, 'Synth tiles must be for roi or partition region'

    roi = Roi(
        db=db,
        x1=j['info']['GRID_X_MIN'],
        y1=j['info']['GRID_Y_MIN'],
        x2=j['info']['GRID_X_MAX'],
        y2=j['info']['GRID_Y_MAX'],
    )

    with DatabaseCache(args.connection_database, read_only=True) as conn:
        synth_tiles['info'] = j['info']
        tile_in_use = set()
        for port in j['ports']:
            if args.roi:
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
            else:
                if port['type'] == 'out':
                    port_type = 'input'
                    is_clock = False
                elif port['type'] == 'in':
                    is_clock = False
                    port_type = 'output'
                elif port['type'] == 'clk':
                    port_type = 'output'
                    is_clock = True
                else:
                    assert False, port

            if args.partition_region:
                tile, wire = find_wire_from_node(conn, g, roi, port['node'])

            if not args.partition_region:
                tile, wire = port['wire'].split('/')

            tile_in_use.add(tile)

            # Make sure connecting wire is not in ROI!
            loc = g.loc_of_tilename(tile)
            print(loc)
            if roi.tile_in_roi(loc):
                # Or if in the ROI, make sure it has no sites.
                gridinfo = g.gridinfo_at_tilename(tile)
                assert len(db.get_tile_type(gridinfo.tile_type).get_sites()
                           ) == 0, "{}/{}".format(tile, wire)

            print(tile)
            vpr_loc = map_tile_to_vpr_coord(conn, tile)

            if tile not in synth_tiles['tiles']:
                synth_tiles['tiles'][tile] = {
                    'pins': [],
                    'loc': vpr_loc,
                }
            if not args.partition_region:
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
            else:
                synth_tiles['tiles'][tile]['pins'].append(
                    {
                        'roi_name':
                            port['name'].replace('[', '_').replace(']', '_'),
                        'wire':
                            wire,
                        'pad':
                            '',
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
