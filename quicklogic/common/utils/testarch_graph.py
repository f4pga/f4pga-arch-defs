#!/usr/bin/env python3

from lib.rr_graph import graph2
from lib.rr_graph import tracks
from lib.rr_graph import points
import lib.rr_graph_xml.graph2 as xml_graph2


# bi-directional channels
def create_tracks(graph, grid_width, grid_height, rcw, verbose=False):
    print("Creating tracks, channel width: %d" % rcw)

    # Not strictly required, but VPR wants this I think?
    assert rcw % 2 == 0

    def alt_pos(begin, end, swap):
        if swap:
            return end, begin, graph2.NodeDirection.DEC_DIR
        else:
            return begin, end, graph2.NodeDirection.INC_DIR

    # chanx going entire width
    for y in range(0, grid_height - 1):
        for tracki in range(rcw):
            begin, end, direction = alt_pos(
                (1, y), (grid_width - 2, y), tracki % 2 == 1
            )

            graph.add_track(
                track=tracks.Track(
                    direction='X',
                    x_low=begin[0],
                    x_high=end[0],
                    y_low=begin[1],
                    y_high=end[1],
                ),
                segment_id=graph.segments[0].id,
                capacity=1,
                direction=direction,
                name="CHANX{:04d}@{:04d}".format(y, tracki),
            )

    # chany going entire height
    for x in range(0, grid_width - 1):
        for tracki in range(rcw):
            begin, end, direction = alt_pos(
                (x, 1), (x, grid_height - 2), tracki % 2 == 1
            )

            graph.add_track(
                track=tracks.Track(
                    direction='Y',
                    x_low=begin[0],
                    x_high=end[0],
                    y_low=begin[1],
                    y_high=end[1],
                ),
                segment_id=graph.segments[0].id,
                capacity=1,
                direction=direction,
                name="CHANY{:04d}@{:04d}".format(x, tracki),
            )


def create_tracks_from_points(
        name, graph, unique_pos, short, grid_width, grid_height
):
    xs, ys = points.decompose_points_into_tracks(
        unique_pos,
        grid_width,
        grid_height,
        right_only=True,
    )
    tracks_list, track_connections = tracks.make_tracks(
        xs, ys, unique_pos, grid_width, grid_height
    )
    tracks_model = tracks.Tracks(tracks_list, track_connections)
    nodes = []
    for idx, track in enumerate(tracks_list):
        nodes.append(
            graph.add_track(
                track=track,
                segment_id=graph.segments[0].id,
                capacity=1,
                name="{}{}".format(name, idx),
            )
        )

    for aidx, bidx in track_connections:
        graph.add_edge(
            src_node=nodes[aidx],
            sink_node=nodes[bidx],
            switch_id=short,
        )
        graph.add_edge(
            src_node=nodes[bidx],
            sink_node=nodes[aidx],
            switch_id=short,
        )

    return nodes, tracks_model


def create_global_constant_tracks(graph, mux, short, grid_width, grid_height):
    """ Create channels for global fanout """
    unique_pos = set()

    for x in range(grid_width):
        for y in range(grid_height):
            if x == 0:
                continue
            if y == 0:
                continue
            if x == grid_width - 1:
                continue
            if y == grid_height - 1:
                continue
            if x == grid_width - 2 and y == grid_height - 2:
                continue

            unique_pos.add((x, y))

    vcc_nodes, vcc_tracks = create_tracks_from_points(
        "VCC", graph, unique_pos, short, grid_width, grid_height
    )
    gnd_nodes, gnd_tracks = create_tracks_from_points(
        "GND", graph, unique_pos, short, grid_width, grid_height
    )

    vcc_pin = graph.create_pin_name_from_tile_type_and_pin('VCC', 'VCC')
    gnd_pin = graph.create_pin_name_from_tile_type_and_pin('GND', 'GND')

    found_vcc = False
    found_gnd = False

    for loc in graph.grid:
        block_type = graph.block_types[loc.block_type_id]

        for pin_class in block_type.pin_class:
            for pin in pin_class.pin:
                if pin.name == vcc_pin:
                    nodes = vcc_nodes
                    tracks = vcc_tracks
                    found_vcc = True
                elif pin.name == gnd_pin:
                    nodes = gnd_nodes
                    tracks = gnd_tracks
                    found_gnd = True
                else:
                    continue

                pin_map = {}

                for pin_node, pin_side in graph.loc_pin_map[(loc.x, loc.y,
                                                             pin.ptc)]:
                    pin_map[pin_side] = pin_node

                made_connection = False
                for pin_dir, idx in tracks.get_tracks_for_wire_at_coord(
                    (loc.x, loc.y)).items():
                    if pin_dir in pin_map:
                        made_connection = True
                        graph.add_edge(
                            src_node=pin_map[pin_side],
                            sink_node=nodes[idx],
                            switch_id=mux,
                        )
                        break

                assert made_connection, (pin, pin_map)

    assert found_vcc
    assert found_gnd


def channel_common(node):
    """ Return the value of the channel that is common.

    Args:
        node (graph2.Node): Node to get common dimension.

    """
    if node.type == graph2.NodeType.CHANX:
        assert node.loc.y_low == node.loc.y_high
        return node.loc.y_low
    elif node.type == graph2.NodeType.CHANY:
        assert node.loc.x_low == node.loc.x_high
        return node.loc.x_low
    else:
        assert False, node.type


def channel_start(node):
    """ Return the start value of the channel

    Args:
        node (graph2.Node): Node to get start dimension.

    """
    if node.type == graph2.NodeType.CHANX:
        return node.loc.x_low
    elif node.type == graph2.NodeType.CHANY:
        return node.loc.y_low
    else:
        assert False, node.type


def walk_pins(graph):
    """ Yields all pins from grid.

    Yield is tuple (graph2.GridLoc, graph2.PinClass, graph2.Pin, pin node idx, tracks.Direction).

    """
    for loc in graph.grid:
        block_type = graph.block_types[loc.block_type_id]

        for pin_class_idx, pin_class in enumerate(block_type.pin_class):
            for pin in pin_class.pin:
                for pin_node, pin_side in graph.loc_pin_map[(loc.x, loc.y,
                                                             pin.ptc)]:
                    yield loc, pin_class, pin, pin_node, pin_side


def connect_blocks_to_tracks(
        graph, grid_width, grid_height, rcw, switch, verbose=False
):
    ytracks = {}

    for inode in graph.tracks:
        if graph.nodes[inode].type == graph2.NodeType.CHANX:
            continue
        elif graph.nodes[inode].type == graph2.NodeType.CHANY:
            x = channel_common(graph.nodes[inode])

            if x not in ytracks:
                ytracks[x] = []
            ytracks[x].append(inode)
        else:
            assert False, graph.nodes[inode]

    special_pins = set(
        (
            graph.create_pin_name_from_tile_type_and_pin('TILE', 'COUT'),
            graph.create_pin_name_from_tile_type_and_pin('TILE', 'CIN'),
            graph.create_pin_name_from_tile_type_and_pin('VCC', 'VCC'),
            graph.create_pin_name_from_tile_type_and_pin('GND', 'GND'),
        )
    )

    print("Indexing nodes")
    print("Skipping connecting block pins to CHANX")
    print("Connecting left-right block pins to CHANY")

    # Walk every pin and connect them to every track on the left or right,
    # depending on pin direction
    #
    # Pins in the TOP/BOTTOM direction are asserted to be the carry pins.
    for loc, pin_class, pin, pin_node, pin_side in walk_pins(graph):
        if pin.name in special_pins:
            continue

        if pin_side == tracks.Direction.LEFT:
            if loc.x == 0:
                continue
            tracks_for_pin = ytracks[loc.x - 1]
        elif pin_side == tracks.Direction.RIGHT:
            if loc.x == grid_width - 1:
                continue
            tracks_for_pin = ytracks[loc.x]
        else:
            assert False, pin_side

        if pin_class.type == graph2.PinType.OUTPUT:
            for track_inode in tracks_for_pin:
                graph.add_edge(
                    src_node=pin_node,
                    sink_node=track_inode,
                    switch_id=switch,
                )
        elif pin_class.type == graph2.PinType.INPUT:
            for track_inode in tracks_for_pin:
                graph.add_edge(
                    src_node=track_inode,
                    sink_node=pin_node,
                    switch_id=switch,
                )


def connect_tracks_to_tracks(graph, switch, verbose=False):
    print("Connecting tracks to tracks")

    def try_connect(ainode, binode):
        """ Connect channel at ainode and binode if possible.

        Args:
            ainode (int): Node index of destination channel
            binode (int): Node index of source channel.

        """
        atrack = graph.nodes[ainode]
        btrack = graph.nodes[binode]

        # Check if source channel can connect to destinatio channel.
        # Note this code assumes unidirectional channels are in use.
        if (btrack.direction == graph2.NodeDirection.INC_DIR
                and channel_start(btrack) <= channel_common(atrack)) \
            or (btrack.direction == graph2.NodeDirection.DEC_DIR
                and channel_start(btrack) >= channel_common(atrack)):
            graph.add_edge(binode, ainode, switch)

    xtracks = []
    ytracks = []

    for inode in graph.tracks:
        if graph.nodes[inode].type == graph2.NodeType.CHANX:
            xtracks.append(inode)
        elif graph.nodes[inode].type == graph2.NodeType.CHANY:
            ytracks.append(inode)
        else:
            assert False, graph.nodes[inode]

    for xinode in xtracks:
        for yinode in ytracks:
            try_connect(xinode, yinode)
            try_connect(yinode, xinode)


def rebuild_graph(fn, fn_out, rcw=6, verbose=False):
    """
    Add rcw tracks spanning full channel to both X and Y channels
    Connect all of those to all the adjacent pins
    Fully connect tracks at intersections
    For intersections this means we actually have two edges per intersection
    since source and sink must be specified
    """

    print('Importing input g')
    xml_graph = xml_graph2.Graph(
        fn,
        output_file_name=fn_out,
    )

    graph = xml_graph.graph

    grid_width = max(p.x for p in graph.grid) + 1
    grid_height = max(p.y for p in graph.grid) + 1

    mux = graph.get_switch_id('mux')

    try:
        short = graph.get_switch_id('short')
    except KeyError:
        short = xml_graph.add_switch(
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

    create_tracks(graph, grid_width, grid_height, rcw, verbose=verbose)
    create_global_constant_tracks(graph, mux, short, grid_width, grid_height)
    connect_blocks_to_tracks(graph, grid_width, grid_height, rcw, switch=mux)
    connect_tracks_to_tracks(graph, switch=mux, verbose=verbose)
    print("Completed rebuild")

    xml_graph.root_attrib["tool_version"] = "dev"
    xml_graph.root_attrib["tool_comment"] = "Generated from black magic"

    channels_obj = graph.create_channels(pad_segment=graph.segments[0].id)

    xml_graph.serialize_to_xml(
        channels_obj=channels_obj,
        connection_box_obj=None,
        nodes_obj=graph.nodes,
        edges_obj=graph.edges
    )


def main():
    import argparse

    parser = argparse.ArgumentParser()
    parser.add_argument("--verbose", action='store_true')
    parser.add_argument("--route_chan_width", type=int, default=20)
    parser.add_argument("--read_rr_graph")
    parser.add_argument("--write_rr_graph")
    args = parser.parse_args()

    rebuild_graph(
        args.read_rr_graph,
        args.write_rr_graph,
        rcw=args.route_chan_width,
        verbose=args.verbose
    )


if __name__ == "__main__":
    main()
