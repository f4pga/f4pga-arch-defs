#!/usr/bin/env python3
""" Imports 7-series routing fabric to the rr graph.

For ROI configurations, this also connects the synthetic IO tiles to the routing
node specified.

Rough structure:

Add rr_nodes for CHANX and CHANY from the database.  IPIN and OPIN rr_nodes
should already be present from the input rr_graph.

Create a mapping between database graph_nodes and IPIN, OPIN, CHANX and CHANY
rr_node ids in the rr_graph.

Add rr_edge for each row in the graph_edge table.

Import channel XML node from connection database and serialize output to
rr_graph XML.

"""

import argparse
from lib.rr_graph import graph2
from lib.rr_graph import tracks
from lib.connection_database import get_wire_pkey, get_track_model
import lib.rr_graph_xml.graph2 as xml_graph2
from lib.rr_graph_xml.utils import read_xml_file
from prjxray_constant_site_pins import feature_when_routed
import simplejson as json
import progressbar
import datetime
import re
import functools

from prjxray_db_cache import DatabaseCache

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
            feature_path[0], feature_path[-1]
        )

        return ' '.join((feature, enable_buffer_feature))

    m = CASCOUT_REGEX.fullmatch(feature_path[-2])
    if m:
        enable_cascout = '{}.CASCOUT_{}_ACTIVE'.format(
            feature_path[0], m.group(1)
        )

        return ' '.join((feature, enable_cascout))

    parts = feature.split('.')

    wire_feature = feature_when_routed(parts[1])
    if wire_feature is not None:
        return '{} {}.{}'.format(feature, parts[0], wire_feature)

    return feature


# BLK_TI-CLBLL_L.CLBLL_LL_A1[0] -> (CLBLL_L, CLBLL_LL_A1)
PIN_NAME_TO_PARTS = re.compile(r'^BLK_TI-([^\.]+)\.([^\]]+)\[0\]$')


def import_graph_nodes(conn, graph, node_mapping):
    c = conn.cursor()
    tile_type_wire_to_pkey = {}
    tile_loc_to_pkey = {}

    for node in graph.nodes:
        if node.type not in (graph2.NodeType.IPIN, graph2.NodeType.OPIN):
            continue

        gridloc = graph.loc_map[(node.loc.x_low, node.loc.y_low)]
        pin_name = graph.pin_ptc_to_name_map[
            (gridloc.block_type_id, node.loc.ptc)]

        # Synthetic blocks are handled below.
        if pin_name.startswith('BLK_SY-'):
            continue

        m = PIN_NAME_TO_PARTS.match(pin_name)
        assert m is not None, pin_name

        pin = m.group(2)

        # Get tile pkey and tile name
        if gridloc not in tile_loc_to_pkey:
            (tile_pkey, tile_type_pkey,) = c.execute("SELECT pkey, tile_type_pkey FROM tile WHERE grid_x = (?) AND grid_y = (?)", (gridloc[0], gridloc[1])).fetchone()
            (tile_type,) = c.execute("SELECT name FROM tile_type WHERE pkey = (?)", (tile_type_pkey,)).fetchone()
            tile_loc_to_pkey[gridloc] = (tile_pkey, tile_type)
        else:
            tile_pkey, tile_type = tile_loc_to_pkey[gridloc]

        key = (tile_type, pin)

        if key not in tile_type_wire_to_pkey:
            c.execute(
                """
SELECT
  pkey
FROM
  wire_in_tile
WHERE
  tile_type_pkey = (
    SELECT
      pkey
    FROM
      tile_type
    WHERE
      name = ?
  )
  AND name = ?;""", (tile_type, pin)
            )

            result = c.fetchone()
            assert result is not None, (tile_type, pin)
            (wire_in_tile_pkey, ) = result

            tile_type_wire_to_pkey[key] = wire_in_tile_pkey
        else:
            wire_in_tile_pkey = tile_type_wire_to_pkey[key]

        c.execute(
            """
        SELECT
            top_graph_node_pkey, bottom_graph_node_pkey,
            left_graph_node_pkey, right_graph_node_pkey FROM wire
            WHERE
              wire_in_tile_pkey = ? AND tile_pkey = ?;""",
            (wire_in_tile_pkey, tile_pkey)
        )

        (
            top_graph_node_pkey, bottom_graph_node_pkey, left_graph_node_pkey,
            right_graph_node_pkey
        ) = c.fetchone()

        #print(wire_in_tile_pkey, tile_pkey, tile_type, gridloc, pin_name, node.loc.side)
        #print(" ", left_graph_node_pkey, right_graph_node_pkey, top_graph_node_pkey, bottom_graph_node_pkey)

        side = node.loc.side
        if side == tracks.Direction.LEFT:
            assert left_graph_node_pkey is not None, (tile_type, pin_name)
            node_mapping[left_graph_node_pkey] = node.id
        elif side == tracks.Direction.RIGHT:
            assert right_graph_node_pkey is not None, (tile_type, pin_name)
            node_mapping[right_graph_node_pkey] = node.id
        elif side == tracks.Direction.TOP:
            assert top_graph_node_pkey is not None, (tile_type, pin_name)
            node_mapping[top_graph_node_pkey] = node.id
        elif side == tracks.Direction.BOTTOM:
            assert bottom_graph_node_pkey is not None, (tile_type, pin_name)
            node_mapping[bottom_graph_node_pkey] = node.id
        else:
            assert False, side


def import_tracks(conn, alive_tracks, node_mapping, graph, segment_id):
    c2 = conn.cursor()
    for (graph_node_pkey, track_pkey, graph_node_type, x_low, x_high, y_low,
         y_high, ptc) in c2.execute("""
    SELECT pkey, track_pkey, graph_node_type, x_low, x_high, y_low, y_high, ptc FROM
        graph_node WHERE track_pkey IS NOT NULL;"""):
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
            track=track, segment_id=segment_id, ptc=ptc
        )


def import_dummy_tracks(conn, graph, segment_id):
    c2 = conn.cursor()

    num_dummy = 0
    for (graph_node_pkey, track_pkey, graph_node_type, x_low, x_high, y_low,
         y_high, ptc) in c2.execute(
             """
    SELECT pkey, track_pkey, graph_node_type, x_low, x_high, y_low, y_high, ptc FROM
        graph_node WHERE (graph_node_type = ? or graph_node_type = ?) and capacity = 0;""",
             (graph2.NodeType.CHANX.value, graph2.NodeType.CHANY.value)):

        node_type = graph2.NodeType(graph_node_type)

        if node_type == graph2.NodeType.CHANX:
            direction = 'X'
            x_low = x_low
        elif node_type == graph2.NodeType.CHANY:
            direction = 'Y'
            y_low = y_low
        else:
            assert False, node_type

        track = tracks.Track(
            direction=direction,
            x_low=x_low,
            x_high=x_high,
            y_low=y_low,
            y_high=y_high,
        )

        graph.add_track(
            track=track, segment_id=segment_id, capacity=0, ptc=ptc
        )
        num_dummy += 1

    return num_dummy


def create_track_rr_graph(conn, graph, node_mapping, segment_id):
    c = conn.cursor()
    c.execute("""SELECT count(*) FROM track;""")
    (num_channels, ) = c.fetchone()

    print('{} Import alive tracks'.format(now()))
    alive_tracks = set()
    for (track_pkey, ) in c.execute("SELECT pkey FROM track WHERE alive = 1;"):
        alive_tracks.add(track_pkey)

    print('{} Importing alive tracks'.format(now()))
    import_tracks(conn, alive_tracks, node_mapping, graph, segment_id)

    print('{} Importing dummy tracks'.format(now()))
    num_dummy = import_dummy_tracks(conn, graph, segment_id)

    print(
        'original {} final {} dummy {}'.format(
            num_channels, len(alive_tracks), num_dummy
        )
    )


def add_synthetic_edges(conn, graph, node_mapping, synth_tiles):
    c = conn.cursor()
    delayless_switch = graph.get_switch_id('__vpr_delayless_switch__')

    c2 = conn.cursor()
    for tile_name, grid_x, grid_y in c2.execute(
            "SELECT name, grid_x, grid_y FROM tile"):
        loc = (grid_x, grid_y)

        if tile_name in synth_tiles['tiles']:
            assert len(synth_tiles['tiles'][tile_name]['pins']) == 1
            for pin in synth_tiles['tiles'][tile_name]['pins']:
                if pin['port_type'] in ['input', 'output']:
                    wire_pkey = get_wire_pkey(conn, tile_name, pin['wire'])
                    c.execute(
                        """
SELECT
  track_pkey
FROM
  node
WHERE
  pkey = (
    SELECT
      node_pkey
    FROM
      wire
    WHERE
      pkey = ?
  );""", (wire_pkey, )
                    )
                    (track_pkey, ) = c.fetchone()
                    assert track_pkey is not None, (
                        tile_name, pin['wire'], wire_pkey
                    )
                elif pin['port_type'] == 'VCC':
                    c.execute('SELECT vcc_track_pkey FROM constant_sources')
                    (track_pkey, ) = c.fetchone()
                elif pin['port_type'] == 'GND':
                    c.execute('SELECT gnd_track_pkey FROM constant_sources')
                    (track_pkey, ) = c.fetchone()
                else:
                    assert False, pin['port_type']
                tracks_model, track_nodes = get_track_model(conn, track_pkey)

                option = list(tracks_model.get_tracks_for_wire_at_coord(loc))
                assert len(option) > 0, (pin, len(option))

                if pin['port_type'] == 'input':
                    tile_type = 'BLK_SY-OUTPAD'
                    wire = 'outpad'
                elif pin['port_type'] == 'output':
                    tile_type = 'BLK_SY-INPAD'
                    wire = 'inpad'
                elif pin['port_type'] == 'VCC':
                    tile_type = 'BLK_SY-VCC'
                    wire = 'VCC'
                elif pin['port_type'] == 'GND':
                    tile_type = 'BLK_SY-GND'
                    wire = 'GND'
                else:
                    assert False, pin

                track_node = track_nodes[option[0][0]]
                assert track_node in node_mapping, (track_node, track_pkey)
                pin_name = graph.create_pin_name_from_tile_type_and_pin(
                    tile_type, wire
                )

                pin_node = graph.get_nodes_for_pin(loc, pin_name)

                if pin['port_type'] == 'input':
                    graph.add_edge(
                        src_node=node_mapping[track_node],
                        sink_node=pin_node[0][0],
                        switch_id=delayless_switch,
                        name='synth_{}_{}'.format(tile_name, pin['wire']),
                    )
                elif pin['port_type'] in ['VCC', 'GND', 'output']:
                    graph.add_edge(
                        src_node=pin_node[0][0],
                        sink_node=node_mapping[track_node],
                        switch_id=delayless_switch,
                        name='synth_{}_{}'.format(tile_name, pin['wire']),
                    )
                else:
                    assert False, pin


def get_switch_name(conn, graph, switch_name_map, switch_pkey):
    assert switch_pkey is not None
    if switch_pkey not in switch_name_map:
        c2 = conn.cursor()
        c2.execute(
            """SELECT name FROM switch WHERE pkey = ?;""", (switch_pkey, )
        )
        (switch_name, ) = c2.fetchone()
        switch_id = graph.get_switch_id(switch_name)
        switch_name_map[switch_pkey] = switch_id
    else:
        switch_id = switch_name_map[switch_pkey]

    return switch_id


def create_get_tile_name(conn):
    c = conn.cursor()

    @functools.lru_cache(maxsize=None)
    def get_tile_name(tile_pkey):
        c.execute(
            """
        SELECT name FROM tile WHERE pkey = ?;
        """, (tile_pkey, )
        )
        return c.fetchone()[0]

    return get_tile_name


def create_get_pip_wire_names(conn):
    c = conn.cursor()

    @functools.lru_cache(maxsize=None)
    def get_pip_wire_names(pip_pkey):
        c.execute(
            """SELECT src_wire_in_tile_pkey, dest_wire_in_tile_pkey
            FROM pip_in_tile WHERE pkey = ? AND is_directional = 1 AND is_pseudo = 0;""",
            (pip_pkey, )
        )
        src_wire_in_tile_pkey, dest_wire_in_tile_pkey = c.fetchone()

        c.execute(
            """SELECT name FROM wire_in_tile WHERE pkey = ?;""",
            (src_wire_in_tile_pkey, )
        )
        (src_net, ) = c.fetchone()

        c.execute(
            """SELECT name FROM wire_in_tile WHERE pkey = ?;""",
            (dest_wire_in_tile_pkey, )
        )
        (dest_net, ) = c.fetchone()

        return (src_net, dest_net)

    return get_pip_wire_names


def import_graph_edges(conn, graph, node_mapping):
    # First yield existing edges
    print('{} Importing existing edges.'.format(now()))
    for edge in graph.edges:
        yield (edge.src_node, edge.sink_node, edge.switch_id, None)

    # Then yield edges from database.
    c = conn.cursor()

    c.execute("SELECT count() FROM graph_edge;" "")
    (num_edges, ) = c.fetchone()

    get_tile_name = create_get_tile_name(conn)
    get_pip_wire_names = create_get_pip_wire_names(conn)

    switch_name_map = {}

    print('{} Importing edges from database.'.format(now()))
    with progressbar.ProgressBar(max_value=num_edges) as bar:
        for idx, (src_graph_node, dest_graph_node, switch_pkey, tile_pkey,
                  pip_pkey) in enumerate(c.execute("""
SELECT
  src_graph_node_pkey,
  dest_graph_node_pkey,
  switch_pkey,
  tile_pkey,
  pip_in_tile_pkey
FROM
  graph_edge;
                """)):
            if src_graph_node not in node_mapping:
                continue

            if dest_graph_node not in node_mapping:
                continue

            if pip_pkey is not None:
                tile_name = get_tile_name(tile_pkey)
                src_net, dest_net = get_pip_wire_names(pip_pkey)

                pip_name = '{}.{}.{}'.format(tile_name, dest_net, src_net)
            else:
                pip_name = None

            switch_id = get_switch_name(
                conn, graph, switch_name_map, switch_pkey
            )

            src_node = node_mapping[src_graph_node]
            sink_node = node_mapping[dest_graph_node]

            if pip_name is not None:
                yield (
                    src_node, sink_node, switch_id,
                    (('fasm_features', check_feature(pip_name)), )
                )
            else:
                yield (src_node, sink_node, switch_id, ())

            if idx % 1024 == 0:
                bar.update(idx)


def create_channels(conn):
    c = conn.cursor()

    c.execute(
        """
    SELECT chan_width_max, x_min, x_max, y_min, y_max FROM channel;"""
    )
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


def yield_nodes(nodes):
    with progressbar.ProgressBar(max_value=len(nodes)) as bar:
        for idx, node in enumerate(nodes):
            yield node

            if idx % 1024 == 0:
                bar.update(idx)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        '--read_rr_graph', required=True, help='Input rr_graph file'
    )
    parser.add_argument(
        '--write_rr_graph', required=True, help='Output rr_graph file'
    )
    parser.add_argument(
        '--connection_database',
        help='Database of fabric connectivity',
        required=True
    )
    parser.add_argument(
        '--synth_tiles',
        help='If using an ROI, synthetic tile defintion from'
        ' prjxray-arch-import'
    )

    args = parser.parse_args()

    if args.synth_tiles:
        use_roi = True
        with open(args.synth_tiles) as f:
            synth_tiles = json.load(f)

        print('{} generating routing graph for ROI.'.format(now()))
    else:
        use_roi = False
        synth_tiles = None

    # Convert input rr graph into graph2.Graph object.
    input_rr_graph = read_xml_file(args.read_rr_graph)

    xml_graph = xml_graph2.Graph(
        input_rr_graph,
        progressbar=progressbar.progressbar,
        output_file_name=args.write_rr_graph,
    )

    graph = xml_graph.graph

    # Add back short switch, which is unused in arch xml, so is not emitted in
    # rrgraph XML.
    #
    # TODO: This can be removed once
    # https://github.com/verilog-to-routing/vtr-verilog-to-routing/issues/354
    # is fixed.
    try:
        graph.get_switch_id('short')
    except KeyError:
        xml_graph.add_switch(
            graph2.Switch(
                id=None,
                name='short',
                type=graph2.SwitchType.SHORT,
                timing=None,
                sizing=graph2.SwitchSizing(
                    mux_trans_size=0,
                    buf_size=0,
                ),
            )
        )

    tool_version = input_rr_graph.getroot().attrib['tool_version']
    tool_comment = input_rr_graph.getroot().attrib['tool_comment']

    with DatabaseCache(args.connection_database, True) as conn:

        # Mapping of graph_node.pkey to rr node id.
        node_mapping = {}

        # Match site pins rr nodes with graph_node's in the connection_database.
        print('{} Importing graph nodes'.format(now()))
        import_graph_nodes(conn, graph, node_mapping)

        # Walk all track graph nodes and add them.
        print('{} Creating tracks'.format(now()))
        segment_id = graph.get_segment_id_from_name('dummy')
        create_track_rr_graph(conn, graph, node_mapping, segment_id)

        # Set of (src, sink, switch_id) tuples that pip edges have been sent to
        # VPR.  VPR cannot handle duplicate paths with the same switch id.
        if use_roi:
            print('{} Adding synthetic edges'.format(now()))
            add_synthetic_edges(conn, graph, node_mapping, synth_tiles)

        print('{} Creating channels.'.format(now()))
        channels_obj = create_channels(conn)

        print('{} Serializing to disk.'.format(now()))
        with xml_graph:
            xml_graph.start_serialize_to_xml(
                tool_version=tool_version,
                tool_comment=tool_comment,
                channels_obj=channels_obj,
            )

            xml_graph.serialize_nodes(yield_nodes(xml_graph.graph.nodes))
            xml_graph.serialize_edges(
                import_graph_edges(conn, graph, node_mapping)
            )


if __name__ == '__main__':
    main()
