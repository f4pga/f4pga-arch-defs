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
import prjxray.db
from prjxray.roi import Roi
import prjxray.grid as grid
from lib.rr_graph import graph2
from lib.rr_graph import tracks
from lib.connection_database import get_wire_pkey, get_track_model, \
        get_wire_in_tile_from_pin_name
import lib.rr_graph_xml.graph2 as xml_graph2
from lib.rr_graph_xml.utils import read_xml_file
from prjxray_constant_site_pins import feature_when_routed
from prjxray_tile_import import remove_vpr_tile_prefix
import simplejson as json
from lib import progressbar_utils
import datetime
import re
import functools
import pickle

from prjxray_db_cache import DatabaseCache

now = datetime.datetime.now

HCLK_CK_BUFHCLK_REGEX = re.compile('HCLK_CK_BUFHCLK[0-9]+')
CASCOUT_REGEX = re.compile('BRAM_CASCOUT_ADDR((?:BWR)|(?:ARD))ADDRU([0-9]+)')
CONNECTION_BOX_FILTER = re.compile('([^0-9]+)[0-9]*')


def reduce_connection_box(box):
    """ Reduce the number of connection boxes by merging some.

    Examples:

    >>> reduce_connection_box('IMUX0')
    'IMUX'
    >>> reduce_connection_box('IMUX1')
    'IMUX'
    >>> reduce_connection_box('IMUX10')
    'IMUX'
    >>> reduce_connection_box('BRAM_ADDR')
    'IMUX'
    >>> reduce_connection_box('A_L10')
    'A'
    >>> reduce_connection_box('B')
    'B'
    >>> reduce_connection_box('B_L')
    'B'

    """

    box = CONNECTION_BOX_FILTER.match(box).group(1)

    if 'BRAM_ADDR' in box:
        box = 'IMUX'

    if box.endswith('_L'):
        box = box.replace('_L', '')

    return box


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


# CLBLL_L.CLBLL_LL_A1[0] -> (CLBLL_L, CLBLL_LL_A1)
PIN_NAME_TO_PARTS = re.compile(r'^([^\.]+)\.([^\]]+)\[0\]$')


def set_connection_box(graph, node_idx, grid_x, grid_y, box_id):
    """ Assign a connection box to an IPIN node. """
    node_dict = graph.nodes[node_idx]._asdict()
    node_dict['connection_box'] = graph2.ConnectionBox(
        x=grid_x,
        y=grid_y,
        id=box_id,
    )
    graph.nodes[node_idx] = graph2.Node(**node_dict)


def update_connection_box(
        conn, graph, graph_node_pkey, node_idx, connection_box_map
):
    """ Update connection box of IPIN node if needed. """
    cur = conn.cursor()

    cur.execute(
        """
SELECT connection_box_wire_pkey
FROM graph_node WHERE pkey = ?""", (graph_node_pkey, )
    )

    connection_box_wire_pkey = cur.fetchone()[0]
    if connection_box_wire_pkey is not None:
        cur.execute(
            """
SELECT grid_x, grid_y FROM phy_tile WHERE pkey = (
    SELECT phy_tile_pkey FROM wire WHERE pkey = ?
    )""", (connection_box_wire_pkey, )
        )
        grid_x, grid_y = cur.fetchone()

        cur.execute(
            "SELECT wire_in_tile_pkey FROM wire WHERE pkey = ?",
            (connection_box_wire_pkey, )
        )
        wire_in_tile_pkey = cur.fetchone()[0]
        box_id = connection_box_map[wire_in_tile_pkey]
        set_connection_box(graph, node_idx, grid_x, grid_y, box_id)


def import_graph_nodes(conn, graph, node_mapping, connection_box_map):
    cur = conn.cursor()
    tile_loc_to_pkey = {}

    for node_idx, node in enumerate(graph.nodes):
        if node.type not in (graph2.NodeType.IPIN, graph2.NodeType.OPIN):
            continue

        gridloc = graph.loc_map[(node.loc.x_low, node.loc.y_low)]
        pin_name = graph.pin_ptc_to_name_map[
            (gridloc.block_type_id, node.loc.ptc)]

        # Synthetic blocks are handled below.
        if pin_name.startswith('SYN-'):
            set_connection_box(
                graph,
                node_idx,
                node.loc.x_low,
                node.loc.y_low,
                box_id=graph.maybe_add_connection_box('IMUX')
            )
            continue

        m = PIN_NAME_TO_PARTS.match(pin_name)
        assert m is not None, pin_name

        tile_type = m.group(1)
        tile_type = remove_vpr_tile_prefix(tile_type)

        pin = m.group(2)

        (wire_in_tile_pkeys, _) = get_wire_in_tile_from_pin_name(
            conn=conn, tile_type_str=tile_type, wire_str=pin
        )

        cur.execute(
            """
SELECT site_as_tile_pkey FROM tile WHERE grid_x = ? AND grid_y = ?;
        """, (node.loc.x_low, node.loc.y_low)
        )
        site_as_tile_pkey = cur.fetchone()[0]

        if site_as_tile_pkey is not None:
            cur.execute(
                """
SELECT site_pkey FROM site_as_tile WHERE pkey = ?;
                """, (site_as_tile_pkey, )
            )
            site_pkey = cur.fetchone()[0]
            wire_in_tile_pkey = wire_in_tile_pkeys[site_pkey]
        else:
            assert len(wire_in_tile_pkeys) == 1
            _, wire_in_tile_pkey = wire_in_tile_pkeys.popitem()

        if gridloc not in tile_loc_to_pkey:
            cur.execute(
                """
            SELECT pkey FROM tile WHERE grid_x = ? AND grid_y = ?;""",
                (gridloc[0], gridloc[1])
            )

            result = cur.fetchone()
            assert result is not None, (tile_type, gridloc)
            (tile_pkey, ) = result
            tile_loc_to_pkey[gridloc] = tile_pkey
        else:
            tile_pkey = tile_loc_to_pkey[gridloc]

        cur.execute(
            """
        SELECT
            top_graph_node_pkey, bottom_graph_node_pkey,
            left_graph_node_pkey, right_graph_node_pkey FROM wire
            WHERE
              wire_in_tile_pkey = ? AND tile_pkey = ?;""",
            (wire_in_tile_pkey, tile_pkey)
        )

        result = cur.fetchone()
        assert result is not None, (wire_in_tile_pkey, tile_pkey)
        (
            top_graph_node_pkey, bottom_graph_node_pkey, left_graph_node_pkey,
            right_graph_node_pkey
        ) = result

        side = node.loc.side
        if side == tracks.Direction.LEFT:
            assert left_graph_node_pkey is not None, (tile_type, pin_name)
            node_mapping[left_graph_node_pkey] = node.id

            update_connection_box(
                conn, graph, left_graph_node_pkey, node_idx, connection_box_map
            )
        elif side == tracks.Direction.RIGHT:
            assert right_graph_node_pkey is not None, (tile_type, pin_name)
            node_mapping[right_graph_node_pkey] = node.id

            update_connection_box(
                conn, graph, right_graph_node_pkey, node_idx,
                connection_box_map
            )
        elif side == tracks.Direction.TOP:
            assert top_graph_node_pkey is not None, (tile_type, pin_name)
            node_mapping[top_graph_node_pkey] = node.id

            update_connection_box(
                conn, graph, top_graph_node_pkey, node_idx, connection_box_map
            )
        elif side == tracks.Direction.BOTTOM:
            assert bottom_graph_node_pkey is not None, (tile_type, pin_name)
            node_mapping[bottom_graph_node_pkey] = node.id

            update_connection_box(
                conn, graph, bottom_graph_node_pkey, node_idx,
                connection_box_map
            )
        else:
            assert False, side


def is_track_alive(conn, tile_pkey, roi, synth_tiles):
    cur = conn.cursor()
    cur.execute(
        """SELECT name, grid_x, grid_y FROM tile WHERE pkey = ?;""",
        (tile_pkey, )
    )
    tile, grid_x, grid_y = cur.fetchone()

    return roi.tile_in_roi(grid.GridLoc(grid_x=grid_x, grid_y=grid_y)
                           ) or tile in synth_tiles['tiles']


def import_tracks(conn, alive_tracks, node_mapping, graph, default_segment_id):
    cur = conn.cursor()
    cur2 = conn.cursor()
    for (graph_node_pkey, track_pkey, graph_node_type, x_low, x_high, y_low,
         y_high, ptc, capacitance, resistance) in cur.execute("""
SELECT
    pkey,
    track_pkey,
    graph_node_type,
    x_low,
    x_high,
    y_low,
    y_high,
    ptc,
    capacitance,
    resistance
FROM
    graph_node WHERE track_pkey IS NOT NULL;"""):
        if track_pkey not in alive_tracks:
            continue

        cur2.execute(
            """
SELECT name FROM segment WHERE pkey = (
    SELECT segment_pkey FROM track WHERE pkey = ?
)""", (track_pkey, )
        )
        result = cur2.fetchone()
        if result is not None:
            segment_name = result[0]
            segment_id = graph.get_segment_id_from_name(segment_name)
        else:
            segment_id = default_segment_id

        node_type = graph2.NodeType(graph_node_type)

        if node_type == graph2.NodeType.CHANX:
            direction = 'X'
            x_low = max(x_low, 1)
        elif node_type == graph2.NodeType.CHANY:
            direction = 'Y'
            y_low = max(y_low, 1)
        else:
            assert False, node_type

        canonical_loc = None
        cur2.execute(
            """
SELECT grid_x, grid_y FROM phy_tile WHERE pkey = (
    SELECT canon_phy_tile_pkey FROM track WHERE pkey = ?
    )""", (track_pkey, )
        )
        result = cur2.fetchone()
        if result:
            canonical_loc = graph2.CanonicalLoc(x=result[0], y=result[1])

        track = tracks.Track(
            direction=direction,
            x_low=x_low,
            x_high=x_high,
            y_low=y_low,
            y_high=y_high,
        )
        assert graph_node_pkey not in node_mapping
        node_mapping[graph_node_pkey] = graph.add_track(
            track=track,
            segment_id=segment_id,
            ptc=ptc,
            timing=graph2.NodeTiming(
                r=resistance,
                c=capacitance,
            ),
            canonical_loc=canonical_loc
        )


def create_track_rr_graph(
        conn, graph, node_mapping, use_roi, roi, synth_tiles, segment_id
):
    cur = conn.cursor()
    cur.execute("""SELECT count(*) FROM track;""")
    (num_channels, ) = cur.fetchone()

    print('{} Import alive tracks'.format(now()))
    alive_tracks = set()
    for (track_pkey,
         ) in cur.execute("SELECT pkey FROM track WHERE alive = 1;"):
        alive_tracks.add(track_pkey)

    print('{} Importing alive tracks'.format(now()))
    import_tracks(conn, alive_tracks, node_mapping, graph, segment_id)

    print('original {} final {}'.format(num_channels, len(alive_tracks)))


def add_synthetic_edges(conn, graph, node_mapping, grid, synth_tiles):
    cur = conn.cursor()
    delayless_switch = graph.get_switch_id('__vpr_delayless_switch__')

    for tile_name, synth_tile in synth_tiles['tiles'].items():
        assert len(synth_tile['pins']) == 1
        for pin in synth_tile['pins']:
            if pin['port_type'] in ['input', 'output']:
                wire_pkey = get_wire_pkey(conn, tile_name, pin['wire'])
                cur.execute(
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
                (track_pkey, ) = cur.fetchone()
                assert track_pkey is not None, (
                    tile_name, pin['wire'], wire_pkey
                )
            elif pin['port_type'] == 'VCC':
                cur.execute('SELECT vcc_track_pkey FROM constant_sources')
                (track_pkey, ) = cur.fetchone()
            elif pin['port_type'] == 'GND':
                cur.execute('SELECT gnd_track_pkey FROM constant_sources')
                (track_pkey, ) = cur.fetchone()
            else:
                assert False, pin['port_type']
            tracks_model, track_nodes = get_track_model(conn, track_pkey)

            option = list(
                tracks_model.get_tracks_for_wire_at_coord(synth_tile['loc'])
            )
            assert len(option) > 0, (pin, len(option))

            if pin['port_type'] == 'input':
                tile_type = 'SYN-OUTPAD'
                wire = 'outpad'
            elif pin['port_type'] == 'output':
                tile_type = 'SYN-INPAD'
                wire = 'inpad'
            elif pin['port_type'] == 'VCC':
                tile_type = 'SYN-VCC'
                wire = 'VCC'
            elif pin['port_type'] == 'GND':
                tile_type = 'SYN-GND'
                wire = 'GND'
            else:
                assert False, pin

            track_node = track_nodes[option[0][0]]
            assert track_node in node_mapping, (track_node, track_pkey)
            pin_name = graph.create_pin_name_from_tile_type_and_pin(
                tile_type, wire
            )

            pin_node = graph.get_nodes_for_pin(
                tuple(synth_tile['loc']), pin_name
            )

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
        cur = conn.cursor()
        cur.execute(
            """SELECT name FROM switch WHERE pkey = ?;""", (switch_pkey, )
        )
        (switch_name, ) = cur.fetchone()
        switch_id = graph.get_switch_id(switch_name)
        switch_name_map[switch_pkey] = switch_id
    else:
        switch_id = switch_name_map[switch_pkey]

    return switch_id


def create_get_tile_name(conn):
    cur = conn.cursor()

    @functools.lru_cache(maxsize=None)
    def get_tile_name(tile_pkey):
        cur.execute(
            """
        SELECT name FROM phy_tile WHERE pkey = ?;
        """, (tile_pkey, )
        )
        return cur.fetchone()[0]

    return get_tile_name


def create_get_pip_wire_names(conn):
    cur = conn.cursor()

    @functools.lru_cache(maxsize=None)
    def get_pip_wire_names(pip_pkey):
        cur.execute(
            """SELECT src_wire_in_tile_pkey, dest_wire_in_tile_pkey
            FROM pip_in_tile WHERE pkey = ? AND is_pseudo = 0;""",
            (pip_pkey, )
        )
        src_wire_in_tile_pkey, dest_wire_in_tile_pkey = cur.fetchone()

        cur.execute(
            """SELECT name FROM wire_in_tile WHERE pkey = ?;""",
            (src_wire_in_tile_pkey, )
        )
        (src_net, ) = cur.fetchone()

        cur.execute(
            """SELECT name FROM wire_in_tile WHERE pkey = ?;""",
            (dest_wire_in_tile_pkey, )
        )
        (dest_net, ) = cur.fetchone()

        return (src_net, dest_net)

    return get_pip_wire_names


def import_graph_edges(conn, graph, node_mapping):
    # First yield existing edges
    print('{} Importing existing edges.'.format(now()))
    for edge in graph.edges:
        yield (edge.src_node, edge.sink_node, edge.switch_id, None)

    # Then yield edges from database.
    cur = conn.cursor()

    cur.execute("SELECT count() FROM graph_edge;" "")
    (num_edges, ) = cur.fetchone()

    get_tile_name = create_get_tile_name(conn)
    get_pip_wire_names = create_get_pip_wire_names(conn)

    switch_name_map = {}

    print('{} Importing edges from database.'.format(now()))
    with progressbar_utils.ProgressBar(max_value=num_edges) as bar:
        for idx, (src_graph_node, dest_graph_node, switch_pkey, phy_tile_pkey,
                  pip_pkey, backward) in enumerate(cur.execute("""
SELECT
  src_graph_node_pkey,
  dest_graph_node_pkey,
  switch_pkey,
  phy_tile_pkey,
  pip_in_tile_pkey,
  backward
FROM
  graph_edge;
                """)):
            if src_graph_node not in node_mapping:
                continue

            if dest_graph_node not in node_mapping:
                continue

            if pip_pkey is not None:
                tile_name = get_tile_name(phy_tile_pkey)
                src_net, dest_net = get_pip_wire_names(pip_pkey)

                if not backward:
                    pip_name = '{}.{}.{}'.format(tile_name, dest_net, src_net)
                else:
                    pip_name = '{}.{}.{}'.format(tile_name, src_net, dest_net)
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
    cur = conn.cursor()

    cur.execute(
        """
    SELECT chan_width_max, x_min, x_max, y_min, y_max FROM channel;"""
    )
    chan_width_max, x_min, x_max, y_min, y_max = cur.fetchone()

    cur.execute('SELECT idx, info FROM x_list;')
    x_list = []
    for idx, info in cur:
        x_list.append(graph2.ChannelList(idx, info))

    cur.execute('SELECT idx, info FROM y_list;')
    y_list = []
    for idx, info in cur:
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


def create_connection_boxes(conn, graph):
    """ Assign connection box ids for all connection box types. """
    cur = conn.cursor()
    cur.execute(
        """
SELECT pkey, tile_type_pkey, name FROM wire_in_tile WHERE pkey IN (
    SELECT DISTINCT wire_in_tile_pkey FROM wire WHERE pkey IN (
        SELECT connection_box_wire_pkey FROM graph_node
        WHERE connection_box_wire_pkey IS NOT NULL
    )
);"""
    )

    connection_box_map = {}
    for wire_in_tile_pkey, tile_type_pkey, wire_name in cur:
        connection_box_map[wire_in_tile_pkey] = graph.maybe_add_connection_box(
            reduce_connection_box(wire_name)
        )

    return connection_box_map


def yield_nodes(nodes):
    with progressbar_utils.ProgressBar(max_value=len(nodes)) as bar:
        for idx, node in enumerate(nodes):
            yield node

            if idx % 1024 == 0:
                bar.update(idx)


def phy_grid_dims(conn):
    """ Returns physical grid dimensions. """
    cur = conn.cursor()
    cur.execute("SELECT grid_x FROM phy_tile ORDER BY grid_x DESC LIMIT 1;")
    x_max = cur.fetchone()[0]
    cur.execute("SELECT grid_y FROM phy_tile ORDER BY grid_y DESC LIMIT 1;")
    y_max = cur.fetchone()[0]

    return x_max + 1, y_max + 1


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        '--db_root', required=True, help='Project X-Ray Database'
    )
    parser.add_argument(
        '--read_rr_graph', required=True, help='Input rr_graph file'
    )
    parser.add_argument(
        '--write_rr_graph', required=True, help='Output rr_graph file'
    )
    parser.add_argument(
        '--write_rr_node_map',
        required=True,
        help='Output map of graph_node_pkey to rr inode file'
    )
    parser.add_argument(
        '--connection_database',
        help='Database of fabric connectivity',
        required=True
    )
    parser.add_argument(
        '--synth_tiles',
        help='If using an ROI, synthetic tile defintion from prjxray-arch-import'
    )

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
        progressbar=progressbar_utils.progressbar,
        output_file_name=args.write_rr_graph,
    )

    graph = xml_graph.graph

    tool_version = input_rr_graph.getroot().attrib['tool_version']
    tool_comment = input_rr_graph.getroot().attrib['tool_comment']

    with DatabaseCache(args.connection_database, True) as conn:
        cur = conn.cursor()
        for name, internal_capacitance, drive_resistance, intrinsic_delay, \
                switch_type in cur.execute("""
SELECT
    name,
    internal_capacitance,
    drive_resistance,
    intrinsic_delay,
    switch_type
FROM
    switch;"""):
            # Add back missing switchs, which were unused in arch xml, and so
            # were not  emitted in rrgraph XML.
            #
            # TODO: This can be removed once
            # https://github.com/verilog-to-routing/vtr-verilog-to-routing/issues/354
            # is fixed.

            try:
                graph.get_switch_id(name)
                continue
            except KeyError:
                xml_graph.add_switch(
                    graph2.Switch(
                        id=None,
                        name=name,
                        type=graph2.SwitchType[switch_type.upper()],
                        timing=graph2.SwitchTiming(
                            r=drive_resistance,
                            c_in=0.0,
                            c_out=0.0,
                            c_internal=internal_capacitance,
                            t_del=intrinsic_delay,
                        ),
                        sizing=graph2.SwitchSizing(
                            mux_trans_size=0,
                            buf_size=0,
                        ),
                    )
                )

        # Mapping of graph_node.pkey to rr node id.
        node_mapping = {}

        print('{} Creating connection box list'.format(now()))
        connection_box_map = create_connection_boxes(conn, graph)

        # Match site pins rr nodes with graph_node's in the connection_database.
        print('{} Importing graph nodes'.format(now()))
        import_graph_nodes(conn, graph, node_mapping, connection_box_map)

        # Walk all track graph nodes and add them.
        print('{} Creating tracks'.format(now()))
        segment_id = graph.get_segment_id_from_name('dummy')
        create_track_rr_graph(
            conn, graph, node_mapping, use_roi, roi, synth_tiles, segment_id
        )

        # Set of (src, sink, switch_id) tuples that pip edges have been sent to
        # VPR.  VPR cannot handle duplicate paths with the same switch id.
        if use_roi:
            print('{} Adding synthetic edges'.format(now()))
            add_synthetic_edges(conn, graph, node_mapping, grid, synth_tiles)

        print('{} Creating channels.'.format(now()))
        channels_obj = create_channels(conn)

        x_dim, y_dim = phy_grid_dims(conn)
        connection_box_obj = graph.create_connection_box_object(
            x_dim=x_dim, y_dim=y_dim
        )

        print('{} Serializing to disk.'.format(now()))
        with xml_graph:
            xml_graph.start_serialize_to_xml(
                tool_version=tool_version,
                tool_comment=tool_comment,
                channels_obj=channels_obj,
                connection_box_obj=connection_box_obj,
            )

            xml_graph.serialize_nodes(yield_nodes(xml_graph.graph.nodes))
            xml_graph.serialize_edges(
                import_graph_edges(conn, graph, node_mapping)
            )

        print('{} Writing node map.'.format(now()))
        with open(args.write_rr_node_map, 'wb') as f:
            pickle.dump(node_mapping, f)
        print('{} Done writing node map.'.format(now()))


if __name__ == '__main__':
    main()
