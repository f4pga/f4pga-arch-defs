#!/usr/bin/env python3

from lib.rr_graph import graph2
from lib.rr_graph import tracks
import lib.rr_graph_xml.graph2 as xml_graph2
from lib.rr_graph_xml.utils import read_xml_file



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
            begin, end, direction = alt_pos((1, y), (grid_width - 2, y),
                                            tracki % 2 == 1)

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
            begin, end, direction = alt_pos((x, 1), (x, grid_height - 2),
                                            tracki % 2 == 1)

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
                name="CHANY{:04d}@{:04d}".format(y, tracki),
                )


def channel_common(node):
    if node.type == graph2.NodeType.CHANX:
        assert node.loc.y_low == node.loc.y_high
        return node.loc.y_low
    elif node.type == graph2.NodeType.CHANY:
        assert node.loc.x_low == node.loc.x_high
        return node.loc.x_low
    else:
        assert False, node.type

def channel_start(node):
    if node.type == graph2.NodeType.CHANX:
        return node.loc.x_low
    elif node.type == graph2.NodeType.CHANY:
        return node.loc.y_low
    else:
        assert False, node.type


def connect_blocks_to_tracks(graph, grid_width, grid_height, rcw, switch, verbose=False):
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

    print("Indexing nodes")
    print("Skipping connecting block pins to CHANX")
    print("Connecting left-right block pins to CHANY")
    for loc in graph.grid:
        block_type = graph.block_types[loc.block_type_id]

        for pin_class_idx, pin_class in enumerate(block_type.pin_class):
            for pin in pin_class.pin:
                for pin_node, pin_side in graph.loc_pin_map[(loc.x, loc.y, pin.ptc)]:
                    if pin_side == tracks.Direction.LEFT:
                        if loc.x == 0:
                            continue
                        tracks_for_pin = ytracks[loc.x-1]
                    elif pin_side == tracks.Direction.RIGHT:
                        if loc.x == grid_width-1:
                            continue
                        tracks_for_pin = ytracks[loc.x]
                    elif pin_side == tracks.Direction.TOP:
                        assert pin.name == 'BLK_TI-TILE.COUT[0]', pin
                        continue
                    elif pin_side == tracks.Direction.BOTTOM:
                        assert pin.name == 'BLK_TI-TILE.CIN[0]', pin
                        continue
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

    # Iterate over all valid x channels and connect to all valid y channels
    # and vice versa as direction implies

    def try_connect(ainode, binode):
        atrack = graph.nodes[ainode]
        btrack = graph.nodes[binode]
        # One of the nodes should be going in and the other should be going out
        # Filter out grossly non-sensical connections that confuse the VPR GUI
        if (btrack.direction == graph2.NodeDirection.INC_DIR
                and channel_start(btrack) <= channel_common(atrack)) \
            or (btrack.direction == graph2.NodeDirection.DEC_DIR
                and channel_start(btrack) > channel_common(atrack)):
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
    input_rr_graph = read_xml_file(fn)
    xml_graph = xml_graph2.Graph(
            input_rr_graph,
            output_file_name=fn_out,
            )

    graph = xml_graph.graph

    grid_width = max(p.x for p in graph.grid) + 1
    grid_height = max(p.y for p in graph.grid) + 1

    mux = graph.get_switch_id('mux')

    create_tracks(graph, grid_width, grid_height, rcw, verbose=verbose)
    connect_blocks_to_tracks(graph, grid_width, grid_height, rcw, switch=mux)
    connect_tracks_to_tracks(graph, switch=mux, verbose=verbose)
    print("Completed rebuild")

    xml_graph.serialize_to_xml(
        tool_version="dev",
        tool_comment="Generated from black magic",
        pad_segment=graph.segments[0].id,
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
        verbose=args.verbose)


if __name__ == "__main__":
    main()
