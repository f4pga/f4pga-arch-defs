#!/usr/bin/env python3
""" Imports 7-series routing fabric to the rr graph.

For ROI configurations, this also connects the synthetic IO tiles to the routing
node specified.

"""

import argparse
import prjxray.db
from prjxray.roi import Roi
import prjxray.grid as grid
from lib.rr_graph import graph2
from lib.rr_graph import tracks
from lib.connection_database import get_wire_pkey, get_track_model
import lib.rr_graph_xml.graph2 as xml_graph2
from lib.rr_graph_xml.utils import read_xml_file
import simplejson as json
import progressbar
import datetime
import re
import sqlite3

now = datetime.datetime.now

HCLK_CK_BUFHCLK_REGEX = re.compile('HCLK_CK_BUFHCLK[0-9]+')
CASCOUT_REGEX = re.compile('BRAM_CASCOUT_ADDR((?:BWR)|(?:ARD))ADDRU([0-9]+)')

def check_feature(feature):
    """ Check if enabling this feature requires other features to be enabled.

    Some pips imply other features.  Example:

    .HCLK_LEAF_CLK_B_BOTL0.HCLK_CK_BUFHCLK10
    implies:
    .ENABLE_BUFFER.HCLK_CK_BUFHCLK10
    """

    feature_path = feature.split('.')

    if HCLK_CK_BUFHCLK_REGEX.fullmatch(feature_path[-1]):
        enable_buffer_feature = '{}.ENABLE_BUFFER.{}'.format(
                feature_path[0],
                feature_path[-1])

        return ' '.join((feature, enable_buffer_feature))

    m = CASCOUT_REGEX.fullmatch(feature_path[-2])
    if m:
        enable_cascout = '{}.CASCOUT_{}_ACTIVE'.format(
                feature_path[0],
                m.group(1))

        return ' '.join((feature, enable_cascout))

    return feature

# BLK_TI-CLBLL_L.CLBLL_LL_A1[0] -> (CLBLL_L, CLBLL_LL_A1)
PIN_NAME_TO_PARTS = re.compile(r'^BLK_TI-([^\.]+)\.([^\]]+)\[0\]$')


def import_graph_nodes(conn, graph, node_mapping):
    c = conn.cursor()
    tile_type_wire_to_pkey = {}
    tile_loc_to_pkey = {}

    for node in progressbar.progressbar(graph.nodes):
        if node.type not in (graph2.NodeType.IPIN, graph2.NodeType.OPIN):
            continue

        gridloc = graph.loc_map[(node.loc.x_low, node.loc.y_low)]
        pin_name = graph.pin_ptc_to_name_map[(gridloc.block_type_id, node.loc.ptc)]

        # Synthetic blocks are handled below.
        if pin_name.startswith('BLK_SY-'):
            continue

        m = PIN_NAME_TO_PARTS.match(pin_name)
        assert m is not None, pin_name

        tile_type = m.group(1)
        pin = m.group(2)

        key = (tile_type, pin)

        if key not in tile_type_wire_to_pkey:
            c.execute("""
            SELECT pkey FROM wire_in_tile WHERE
                tile_type_pkey = (SELECT pkey FROM tile_type WHERE name = ?) AND
                name = ?;""", (tile_type, pin))

            result = c.fetchone()
            assert result is not None, (tile_type, pin)
            (wire_in_tile_pkey,) = result

            tile_type_wire_to_pkey[key] = wire_in_tile_pkey
        else:
            wire_in_tile_pkey = tile_type_wire_to_pkey[key]

        if gridloc not in tile_loc_to_pkey:
            c.execute("""
            SELECT pkey FROM tile WHERE grid_x = ? AND grid_y = ?;""",
            (gridloc[0], gridloc[1]))

            (tile_pkey,) = c.fetchone()
            tile_loc_to_pkey[gridloc] = tile_pkey
        else:
            tile_pkey = tile_loc_to_pkey[gridloc]

        c.execute("""
        SELECT
            top_graph_node_pkey, bottom_graph_node_pkey,
            left_graph_node_pkey, right_graph_node_pkey FROM wire
            WHERE
              wire_in_tile_pkey = ? AND tile_pkey = ?;""",
              (wire_in_tile_pkey, tile_pkey))

        (
            top_graph_node_pkey, bottom_graph_node_pkey,
            left_graph_node_pkey, right_graph_node_pkey
            ) = c.fetchone()

        side = node.loc.side
        if side == graph2.Direction.LEFT:
            assert left_graph_node_pkey is not None, (tile_type, pin_name)
            node_mapping[left_graph_node_pkey] = node.id
        elif side == graph2.Direction.RIGHT:
            assert right_graph_node_pkey is not None, (tile_type, pin_name)
            node_mapping[right_graph_node_pkey] = node.id
        elif side == graph2.Direction.TOP:
            assert top_graph_node_pkey is not None, (tile_type, pin_name)
            node_mapping[top_graph_node_pkey] = node.id
        elif side == graph2.Direction.BOTTOM:
            assert bottom_graph_node_pkey is not None, (tile_type, pin_name)
            node_mapping[bottom_graph_node_pkey] = node.id
        else:
            assert False, side

def is_track_alive(conn, tile_pkey, roi, synth_tiles):
    c = conn.cursor()
    c.execute("""SELECT name, grid_x, grid_y FROM tile WHERE pkey = ?;""", (tile_pkey,))
    tile, grid_x, grid_y = c.fetchone()

    return roi.tile_in_roi(grid.GridLoc(grid_x=grid_x, grid_y=grid_y)) or tile in synth_tiles['tiles']

def import_tracks(conn, alive_tracks, node_mapping, graph, segment_id):
    c2 = conn.cursor()
    for (graph_node_pkey, track_pkey, graph_node_type, x_low, x_high, y_low, y_high, ptc) in progressbar.progressbar(c2.execute("""
    SELECT pkey, track_pkey, graph_node_type, x_low, x_high, y_low, y_high, ptc FROM
        graph_node WHERE track_pkey IS NOT NULL;""")):
        if track_pkey not in alive_tracks:
            continue

        node_type = graph2.NodeType(graph_node_type)

        if node_type == graph2.NodeType.CHANX:
            direction = 'X'
            x_low = max(x_low, 1)
        elif node_type == graph2.NodeType.CHANY:
            direction = 'Y'
            y_low = max(y_low, 1)
        else:
            assert False, node_type

        track = tracks.Track(
                direction=direction,
                x_low=x_low,
                x_high=x_high,
                y_low=y_low,
                y_high=y_high,
                )
        assert graph_node_pkey not in node_mapping
        node_mapping[graph_node_pkey] = graph.add_track(
                track=track, segment_id=segment_id,
                name='track_{}'.format(graph_node_pkey))
        graph.set_track_ptc(node_mapping[graph_node_pkey], ptc)

def import_dummy_tracks(conn, graph, segment_id):
    c2 = conn.cursor()

    num_dummy = 0
    for (graph_node_pkey, track_pkey, graph_node_type, x_low, x_high,
        y_low, y_high, ptc) in progressbar.progressbar(c2.execute("""
    SELECT pkey, track_pkey, graph_node_type, x_low, x_high, y_low, y_high, ptc FROM
        graph_node WHERE (graph_node_type = ? or graph_node_type = ?) and capacity = 0;""",
        (graph2.NodeType.CHANX.value, graph2.NodeType.CHANY.value))):

        node_type = graph2.NodeType(graph_node_type)

        if node_type == graph2.NodeType.CHANX:
            direction = 'X'
            x_low = max(x_low, 1)
        elif node_type == graph2.NodeType.CHANY:
            direction = 'Y'
            y_low = max(y_low, 1)
        else:
            assert False, node_type

        track = tracks.Track(
                direction=direction,
                x_low=x_low,
                x_high=x_high,
                y_low=y_low,
                y_high=y_high,
                )

        inode = graph.add_track(
                track=track, segment_id=segment_id,
                name='dummy_track_{}'.format(graph_node_pkey),
                capacity=0)
        graph.set_track_ptc(inode, ptc)
        num_dummy += 1

    return num_dummy

def create_track_rr_graph(conn, graph, node_mapping, use_roi, roi, synth_tiles, segment_id):
    c = conn.cursor()
    c.execute("""SELECT count(*) FROM track;""")
    (num_channels,) = c.fetchone()

    print('{} Import alive tracks'.format(now()))
    alive_tracks = set()
    for (track_pkey,) in c.execute("SELECT pkey FROM track WHERE alive = 1;"):
        alive_tracks.add(track_pkey)

    print('{} Importing alive tracks'.format(now()))
    import_tracks(conn, alive_tracks, node_mapping, graph, segment_id)

    print('{} Importing dummy tracks'.format(now()))
    dummy = import_dummy_tracks(conn, graph, segment_id)

    print('original {} final {} dummy {}'.format(
        num_channels, len(alive_tracks), dummy))

def add_synthetic_edges(conn, graph, node_mapping, grid, synth_tiles):
    c = conn.cursor()
    routing_switch = graph.get_switch_id('routing')

    for loc in progressbar.progressbar(grid.tile_locations()):
        tile_name = grid.tilename_at_loc(loc)

        if tile_name in synth_tiles['tiles']:
            assert len(synth_tiles['tiles'][tile_name]['pins']) == 1
            for pin in synth_tiles['tiles'][tile_name]['pins']:
                wire_pkey = get_wire_pkey(conn, tile_name, pin['wire'])
                c.execute("""SELECT track_pkey FROM node WHERE pkey = (
                    SELECT node_pkey FROM wire WHERE pkey = ?
                    );""", (wire_pkey,))
                (track_pkey,) = c.fetchone()
                assert track_pkey is not None, (tile_name, pin['wire'], wire_pkey)
                tracks_model, track_nodes = get_track_model(conn, track_pkey)

                option = list(tracks_model.get_tracks_for_wire_at_coord(loc))
                assert len(option) > 0

                if pin['port_type'] == 'input':
                    tile_type = 'BLK_SY-OUTPAD'
                    wire = 'outpad'
                elif pin['port_type'] == 'output':
                    tile_type = 'BLK_SY-INPAD'
                    wire = 'inpad'
                else:
                    assert False, pin

                track_node = track_nodes[option[0][0]]
                assert track_node in node_mapping, (track_node, track_pkey)
                pin_name = graph.create_pin_name_from_tile_type_and_pin(
                        tile_type,
                        wire)

                pin_node = graph.get_nodes_for_pin(loc, pin_name)

                if pin['port_type'] == 'input':
                    graph.add_edge(
                            src_node=node_mapping[track_node],
                            sink_node=pin_node[0][0],
                            switch_id=routing_switch,
                            name='synth_{}_{}'.format(tile_name, pin['wire']),
                    )
                elif pin['port_type'] == 'output':
                    graph.add_edge(
                            src_node=pin_node[0][0],
                            sink_node=node_mapping[track_node],
                            switch_id=routing_switch,
                            name='synth_{}_{}'.format(tile_name, pin['wire']),
                    )
                else:
                    assert False, pin

def get_switch_name(conn, graph, switch_name_map, switch_pkey):
    assert switch_pkey is not None
    c2 = conn.cursor()
    if switch_pkey not in switch_name_map:
        c2.execute("""SELECT name FROM switch WHERE pkey = ?;""", (switch_pkey,))
        (switch_name,) = c2.fetchone()
        switch_id = graph.get_switch_id(switch_name)
        switch_name_map[switch_pkey] = switch_id
    else:
        switch_id = switch_name_map[switch_pkey]

    return switch_id

def get_tile_name(conn, tile_name_cache, tile_pkey):
    if tile_pkey in tile_name_cache:
        return tile_name_cache[tile_pkey]
    else:
        c = conn.cursor()
        c.execute("""
        SELECT name FROM tile WHERE pkey = ?;
        """, (tile_pkey,))
        (tile_name,) = c.fetchone()

        tile_name_cache[tile_pkey] = tile_name
        return tile_name

def get_pip_wire_names(conn, pip_cache, pip_pkey):
    if pip_pkey in pip_cache:
        return pip_cache[pip_pkey]
    else:
        c = conn.cursor()
        c.execute("""SELECT src_wire_in_tile_pkey, dest_wire_in_tile_pkey
            FROM pip_in_tile WHERE pkey = ?;""", (pip_pkey,))
        src_wire_in_tile_pkey, dest_wire_in_tile_pkey = c.fetchone()

        c.execute("""SELECT name FROM wire_in_tile WHERE pkey = ?;""",
                (src_wire_in_tile_pkey,))
        (src_net,) = c.fetchone()

        c.execute("""SELECT name FROM wire_in_tile WHERE pkey = ?;""",
                (dest_wire_in_tile_pkey,))
        (dest_net,) = c.fetchone()

        pip_cache[pip_pkey] = (src_net, dest_net)
        return (src_net, dest_net)


def make_fasm_feature(conn, tile_name_cache, pip_cache, tile_pkey, pip_pkey):
    assert tile_pkey is not None

    tile_name = get_tile_name(conn, tile_name_cache, tile_pkey)
    src_net, dest_net = get_pip_wire_names(conn, pip_cache, pip_pkey)

    return '{}.{}.{}'.format(tile_name, dest_net, src_net)

def import_graph_edge(conn, added_edges, graph, node_mapping, src_graph_node, dest_graph_node, switch_id, pip_name):
    src_node = node_mapping[src_graph_node]
    sink_node = node_mapping[dest_graph_node]

    assert (src_node, sink_node) not in added_edges, (
            src_node, sink_node,
            pip_name, src_graph_node, dest_graph_node)

    added_edges.add((src_node, sink_node))

    if pip_name is not None:
        graph.add_edge(
                src_node=src_node, sink_node=sink_node, switch_id=switch_id,
                name='fasm_features', value=check_feature(pip_name))
    else:
        graph.add_edge(
                src_node=src_node, sink_node=sink_node, switch_id=switch_id)

def import_graph_edges(conn, graph, node_mapping):
    c = conn.cursor()

    c.execute("SELECT count() FROM graph_edge;""")
    (num_edges,) = c.fetchone()

    tile_name_cache = {}
    pip_cache = {}
    switch_name_map = {}

    added_edges = set()

    with progressbar.ProgressBar(max_value=num_edges) as bar:
        for idx, (src_graph_node, dest_graph_node, switch_pkey, tile_pkey, pip_pkey) in enumerate(c.execute("""
    SELECT src_graph_node_pkey, dest_graph_node_pkey, switch_pkey, tile_pkey, pip_in_tile_pkey
        FROM graph_edge;
                """)):
            if src_graph_node not in node_mapping:
                continue

            if dest_graph_node not in node_mapping:
                continue

            if pip_pkey is not None:
                pip_name = make_fasm_feature(conn, tile_name_cache, pip_cache, tile_pkey, pip_pkey)
            else:
                pip_name = None

            switch_id = get_switch_name(conn, graph, switch_name_map, switch_pkey)

            import_graph_edge(conn, added_edges, graph, node_mapping, src_graph_node, dest_graph_node, switch_id, pip_name)
            bar.update(idx)

def create_channels(conn):
    c = conn.cursor()

    c.execute("""
    SELECT chan_width_max, x_min, x_max, y_min, y_max FROM channel;""")
    chan_width_max, x_min, x_max, y_min, y_max = c.fetchone()

    c.execute('SELECT idx, info FROM x_list;')
    x_list = []
    for idx, info in c:
        x_list.append(graph2.ChannelList(idx, info))

    c.execute('SELECT idx, info FROM y_list;')
    y_list = []
    for idx, info in c:
        y_list.append(graph2.ChannelList(idx, info))

    return graph2.Channels(
            chan_width_max=chan_width_max,
            x_min=x_min,
            y_min=y_min,
            x_max=x_max,
            y_max=y_max,
            x_list=x_list,
            y_list=y_list,
    )

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
            '--db_root', required=True, help='Project X-Ray Database')
    parser.add_argument(
            '--read_rr_graph', required=True, help='Input rr_graph file')
    parser.add_argument(
            '--write_rr_graph', required=True, help='Output rr_graph file')
    parser.add_argument(
            '--connection_database', help='Database of fabric connectivity', required=True)
    parser.add_argument(
            '--synth_tiles', help='If using an ROI, synthetic tile defintion from prjxray-arch-import')

    args = parser.parse_args()

    db = prjxray.db.Database(args.db_root)
    grid = db.grid()

    if args.synth_tiles:
        use_roi = True
        with open(args.synth_tiles) as f:
            synth_tiles = json.load(f)

        roi = Roi(
                db=db,
                x1=synth_tiles['info']['GRID_X_MIN'],
                y1=synth_tiles['info']['GRID_Y_MIN'],
                x2=synth_tiles['info']['GRID_X_MAX'],
                y2=synth_tiles['info']['GRID_Y_MAX'],
                )

        print('{} generating routing graph for ROI.'.format(now()))
    else:
        use_roi = False

    # Convert input rr graph into graph2.Graph object.
    input_rr_graph = read_xml_file(args.read_rr_graph)

    xml_graph = xml_graph2.Graph(
            input_rr_graph,
            progressbar=progressbar.progressbar)

    graph = xml_graph.graph

    tool_version = input_rr_graph.getroot().attrib['tool_version']
    tool_comment = input_rr_graph.getroot().attrib['tool_comment']

    conn = sqlite3.connect(args.connection_database)

    # Mapping of graph_node.pkey to rr node id.
    node_mapping = {}

    # Match site pins rr nodes with graph_node's in the connection_database.
    print('{} Importing graph nodes'.format(now()))
    import_graph_nodes(conn, graph, node_mapping)

    # Walk all track graph nodes and add them.
    print('{} Creating tracks'.format(now()))
    segment_id = graph.get_segment_id_from_name('dummy')
    create_track_rr_graph(conn, graph, node_mapping, use_roi, roi, synth_tiles, segment_id)

    # Set of (src, sink, switch_id) tuples that pip edges have been sent to
    # VPR.  VPR cannot handle duplicate paths with the same switch id.
    if use_roi:
        print('{} Adding synthetic edges'.format(now()))
        add_synthetic_edges(conn, graph, node_mapping, grid, synth_tiles)

    print('{} Importing edges from database.'.format(now()))
    import_graph_edges(conn, graph, node_mapping)

    print('{} Creating channels.'.format(now()))
    channels_obj = create_channels(conn)

    print('{} Serializing.'.format(now()))
    serialized_rr_graph = xml_graph.serialize_to_xml(
            tool_version=tool_version,
            tool_comment=tool_comment,
            pad_segment=segment_id,
            channels_obj=channels_obj,
    )

    print('{} Writing to disk.'.format(now()))
    with open(args.write_rr_graph, "wb") as f:
        f.write(serialized_rr_graph)
    print('{} Done.'.format(now()))

if __name__ == '__main__':
    main()

