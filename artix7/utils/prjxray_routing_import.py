#!/usr/bin/env python3
""" Imports 7-series routing fabric to the rr graph.

For ROI configurations, this also connects the synthetic IO tiles to the routing
node specified.

"""

import argparse
import prjxray.db
from lib.rr_graph import graph2
from lib.rr_graph import tracks
import lib.rr_graph_xml.graph2 as xml_graph2
from lib.rr_graph_xml.utils import read_xml_file
import simplejson as json
import progressbar
import datetime
import multiprocessing
import pickle
import re

now = datetime.datetime.now

def find_nodes(graph, track_wire_map, loc, tile_name, tile_type, wire):
    """ Finds nodes for the give tile, wire.  This can return multiple nodes.

    Return type is (node_type, node, side)

    For channels, multiple nodes means multiple adjacent channels that make
    the tile/wire pair.

    For site pins, multiple nodes means multiple sides of the tile have that
    pin.
    """

    vpr_tile_name = 'BLK_TI-{}'.format(tile_type)

    pin_name = graph.create_pin_name_from_tile_type_and_pin(vpr_tile_name, wire)

    try:
        site_pin_node = graph.get_nodes_for_pin(loc, pin_name)
    except:
        site_pin_node = None

    if (tile_name, wire) in track_wire_map:
        # This pair appears to be a channel.

        # tile/wire pairs should not be both a channel and a site pin.
        assert site_pin_node is None

        tracks_model, track_nodes = track_wire_map[(tile_name, wire)]

        for idx, pin_dir in tracks_model.get_tracks_for_wire_at_coord(loc):
            node = track_nodes[idx]
            node_type = graph.nodes[node].type

            assert node_type in (graph2.NodeType.CHANX, graph2.NodeType.CHANY)
            yield (node_type, node, pin_dir)
    else:
        if site_pin_node is None:
            return

        for node, pin_dir in site_pin_node:
            node_type = graph.nodes[node].type
            assert node_type in (graph2.NodeType.IPIN, graph2.NodeType.OPIN)
            yield (node_type, node, pin_dir)

def opposite_direction(direction):
    if direction == tracks.Direction.LEFT:
        return tracks.Direction.RIGHT
    elif direction == tracks.Direction.RIGHT:
        return tracks.Direction.LEFT
    elif direction == tracks.Direction.TOP:
        return tracks.Direction.BOTTOM
    elif direction == tracks.Direction.BOTTOM:
        return tracks.Direction.TOP
    else:
        assert False, direction

HCLK_CK_BUFHCLK_REGEX = re.compile('HCLK_CK_BUFHCLK[0-9]+')

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

    return feature

def make_connection(graph, track_wire_map, loc, tile_name, tile_type, pip, switch_id, edges_with_mux, grid, pip_set):
    src_pin = {}
    src_node_type = None
    sink_node_type = None

    pip_name = '{}.{}.{}'.format(tile_name, pip.net_to, pip.net_from)

    for src_node_type, src_node, src_pin_dir in find_nodes(graph, track_wire_map, loc, tile_name, tile_type, pip.net_from):
        src_pin[src_pin_dir] = src_node

    if src_node_type is None:
        return

    src_is_chan = src_node_type in (graph2.NodeType.CHANX, graph2.NodeType.CHANY)

    if pip.name in edges_with_mux:
        if (tile_name, pip.net_from) in edges_with_mux[pip.name]:
            # Found edge with mux!
            assert not src_is_chan

            for target_tile, target_wire in edges_with_mux[pip.name][(tile_name, pip.net_from)]:
                gridinfo = grid.gridinfo_at_tilename(target_tile)
                target_loc = grid.loc_of_tilename(target_tile)


                for sink_node_type, sink_node, sink_pin_dir in find_nodes(
                        graph=graph,
                        track_wire_map=track_wire_map,
                        loc=target_loc,
                        tile_name=target_tile,
                        tile_type=gridinfo.tile_type,
                        wire=target_wire):

                    node_type = graph.nodes[sink_node].type
                    if node_type != graph2.NodeType.IPIN:
                        continue

                    if (src_node, sink_node, switch_id) in pip_set:
                        return

                    pip_set.add((src_node, sink_node, switch_id))
                    graph.add_edge(
                            src_node=src_pin[opposite_direction(sink_pin_dir)], sink_node=sink_node, switch_id=switch_id,
                            name='fasm_features', value=check_feature(pip_name))
                    return (src_node, sink_node, switch_id)

    for sink_node_type, sink_node, sink_pin_dir in find_nodes(graph, track_wire_map, loc, tile_name, tile_type, pip.net_to):
        sink_is_chan = sink_node_type in (graph2.NodeType.CHANX, graph2.NodeType.CHANY)

        if src_is_chan and sink_is_chan:
            if (src_node, sink_node, switch_id) in pip_set:
                return

            pip_set.add((src_node, sink_node, switch_id))
            graph.add_edge(
                    src_node=src_node, sink_node=sink_node, switch_id=switch_id,
                    name='fasm_features', value=check_feature(pip_name))

            return (src_node, sink_node, switch_id)

        if not src_is_chan and not sink_is_chan:
            if (src_node, sink_node, switch_id) in pip_set:
                return

            # Both pins, just make the connection.
            pip_set.add((src_node, sink_node, switch_id))
            graph.add_edge(
                    src_node=src_node, sink_node=sink_node, switch_id=switch_id,
                    name='fasm_features', value=check_feature(pip_name))

            return (src_node, sink_node, switch_id)

        if sink_pin_dir in src_pin:
            if (src_node, sink_node, switch_id) in pip_set:
                return

            pip_set.add((src_node, sink_node, switch_id))
            graph.add_edge(
                    src_node=src_pin[sink_pin_dir], sink_node=sink_node, switch_id=switch_id,
                    name='fasm_features', value=check_feature(pip_name))
            return (src_node, sink_node, switch_id)

    if sink_node_type is not None:
        assert False, (tile_name, pip)

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
            '--db_root', required=True, help='Project X-Ray Database')
    parser.add_argument(
            '--read_rr_graph', required=True, help='Input rr_graph file')
    parser.add_argument(
            '--write_rr_graph', required=True, help='Output rr_graph file')
    parser.add_argument(
            '--channels', required=True, help='Channel definitions from prjxray_form_channels')
    parser.add_argument(
            '--synth_tiles', help='If using an ROI, synthetic tile defintion from prjxray-arch-import')

    args = parser.parse_args()

    db = prjxray.db.Database(args.db_root)
    grid = db.grid()

    if args.synth_tiles:
        use_roi = True
        with open(args.synth_tiles) as f:
            synth_tiles = json.load(f)
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

    delayless_switch = graph.get_delayless_switch_id()

    print('{} reading channels definitions.'.format(now()))
    with open(args.channels) as f:
        channels = json.load(f)

    segment_id = graph.get_segment_id_from_name('dummy')

    track_wire_map = {}

    print('{} add nodes for all channels.'.format(now()))
    used_channels = 0
    for idx, channel in progressbar.progressbar(enumerate(channels['channels'])):
        # Don't use dead channels if using an ROI.
        # Consider a channel alive if at least 1 wire in the node is part of a
        # live tile.
        if use_roi:
            alive = False
            for tile, wire in channel['wires']:
                if grid.gridinfo_at_tilename(tile).in_roi or tile in synth_tiles:
                    alive = True
                    break

            if not alive:
                continue

        used_channels += 1
        nodes = []
        track_list = []
        for idx2, track_dict in enumerate(channel['tracks']):
            if track_dict['direction'] == 'X':
                track_dict['x_low'] = max(track_dict['x_low'], 1)
            elif track_dict['direction'] == 'Y':
                track_dict['y_low'] = max(track_dict['y_low'], 1)
            track = tracks.Track(**track_dict)
            track_list.append(track)

            nodes.append(graph.add_track(track=track, segment_id=segment_id, name='track_{}_{}'.format(idx, idx2)))

        for a_idx, b_idx in channel['track_connections']:
            graph.add_edge(nodes[a_idx], nodes[b_idx], delayless_switch, 'track_{}_to_{}'.format(a_idx, b_idx))
            graph.add_edge(nodes[b_idx], nodes[a_idx], delayless_switch, 'track_{}_to_{}'.format(b_idx, a_idx))

        tracks_model = tracks.Tracks(track_list, channel['track_connections'])

        for tile, wire in channel['wires']:
            track_wire_map[(tile, wire)] = (tracks_model, nodes)

    print('original {} final {}'.format(len(channels['channels']), used_channels))

    routing_switch = graph.get_switch_id('routing')

    pip_map = {}

    edges_with_mux = {}
    for idx, edge_with_mux in progressbar.progressbar(enumerate(channels['edges_with_mux'])):
        if edge_with_mux['pip'] not in edges_with_mux:
            edges_with_mux[edge_with_mux['pip']] = {}

        assert len(edge_with_mux['source_node']) == 1
        edges_with_mux[edge_with_mux['pip']][tuple(edge_with_mux['source_node'][0])] = edge_with_mux['destination_node']

    # Set of (src, sink, switch_id) tuples that pip edges have been sent to
    # VPR.  VPR cannot handle duplicate paths with the same switch id.
    pip_set = set()
    print('{} Adding edges'.format(now()))
    for loc in progressbar.progressbar(grid.tile_locations()):
        gridinfo = grid.gridinfo_at_loc(loc)
        tile_name = grid.tilename_at_loc(loc)

        if use_roi:
            if tile_name in synth_tiles:
                assert len(synth_tiles[tile_name]['pins']) == 1
                for pin in synth_tiles[tile_name]['pins']:
                    tracks_model, track_nodes = track_wire_map[(tile_name, pin['wire'])]

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
                    pin_name = graph.create_pin_name_from_tile_type_and_pin(
                            tile_type,
                            wire)

                    pin_node = graph.get_nodes_for_pin(loc, pin_name)

                    if pin['port_type'] == 'input':
                        graph.add_edge(
                                src_node=track_node,
                                sink_node=pin_node[0][0],
                                switch_id=routing_switch,
                                name='synth_{}_{}'.format(tile_name, pin['wire']),
                        )
                    elif pin['port_type'] == 'output':
                        graph.add_edge(
                                src_node=pin_node[0][0],
                                sink_node=track_node,
                                switch_id=routing_switch,
                                name='synth_{}_{}'.format(tile_name, pin['wire']),
                        )
                    else:
                        assert False, pin
            else:
                # Not a synth node, check if in ROI.
                if not gridinfo.in_roi:
                    continue

        tile_type = db.get_tile_type(gridinfo.tile_type)

        for pip in tile_type.get_pips():
            if pip.is_pseudo:
                continue

            if not pip.is_directional:
                # TODO: Handle bidirectional pips?
                continue

            edge_node = make_connection(graph, track_wire_map, loc, tile_name, gridinfo.tile_type,
                            pip, routing_switch, edges_with_mux, grid, pip_set)

            if edge_node is not None:
                pip_map[(tile_name, pip.name)] = edge_node

    print('{} Writing node mapping.'.format(now()))
    node_mapping = {
            'pips': [],
            'tracks': []
        }

    for (tile, pip_name), edge in pip_map.items():
        node_mapping['pips'].append({
                'tile': tile,
                'pip': pip_name,
                'edge': edge
        })

    for (tile, wire), (_, nodes) in track_wire_map.items():
        node_mapping['tracks'].append({
                'tile': tile,
                'wire': wire,
                'nodes': nodes,
        })

    with open('node_mapping.pickle', 'wb') as f:
        pickle.dump(node_mapping, f)

    print('{} Create channels and serializing.'.format(now()))
    pool = multiprocessing.Pool(10)
    serialized_rr_graph = xml_graph.serialize_to_xml(
            tool_version=tool_version,
            tool_comment=tool_comment,
            pad_segment=segment_id,
            pool=pool,
    )

    print('{} Writing to disk.'.format(now()))
    with open(args.write_rr_graph, "wb") as f:
        f.write(serialized_rr_graph)
    print('{} Done.'.format(now()))

if __name__ == '__main__':
    main()

