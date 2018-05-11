import lib.rr_graph.graph as g
import lib.rr_graph.channel as channel
from lib.rr_graph import Position

import sys
import lxml.etree as ET
import os


# bi-directional channels
def create_tracks(g, grid_sz, rcw, verbose=False):
    print("Creating tracks, channel width: %d" % rcw)
    print("Block grid size: %s" % (g.block_grid.size, ))
    print("Channel grid size: %s" % (g.channels.size, ))

    # Not strictly required, but VPR wants this I think?
    assert rcw % 2 == 0

    seg_timing = {'R_per_meter': 420, 'C_per_meter': 3.e-14}
    segment = g.channels.create_segment('awesomesauce', timing=seg_timing)

    def alt_pos(begin, end, swap):
        if swap:
            return end, begin, channel.Track.Direction.DEC
        else:
            return begin, end, channel.Track.Direction.INC

    # chanx going entire width
    for y in range(0, grid_sz.height - 1):
        if verbose:
            print()
        for tracki in range(rcw):
            begin, end, direction = alt_pos((1, y), (grid_sz.width - 2, y),
                                            tracki % 2 == 1)
            track, _track_node = g.create_xy_track(
                begin,
                end,
                segment,
                type=channel.Track.Type.X,
                direction=direction)
            assert tracki == track.idx, 'Expect index %s, got %s' % (tracki,
                                                                     track.idx)
            if verbose:
                print("Create track %s" % (track, ))
    g.channels.x.assert_width(rcw)
    g.channels.x.assert_full()

    # chany going entire height
    for x in range(0, grid_sz.width - 1):
        if verbose:
            print()
        for tracki in range(rcw):
            begin, end, direction = alt_pos((x, 1), (x, grid_sz.height - 2),
                                            tracki % 2 == 1)
            track, _track_node = g.create_xy_track(
                begin,
                end,
                segment,
                type=channel.Track.Type.Y,
                direction=direction)
            assert tracki == track.idx, 'Expect index %s, got %s' % (tracki,
                                                                     track.idx)
            if verbose:
                print("Create track %s" % (track, ))
    g.channels.y.assert_width(rcw)
    g.channels.y.assert_full()


def connect_blocks_to_tracks(g, grid_sz, rcw, switch, verbose=False):
    # FIXME: performance issue here (takes a couple seconds on my machine)
    # Will likely run into issues on real devices

    def connect_block_to_track(block, tracks, node_index):
        '''Connect all block pins to given track'''
        assert type(block) is g.Block, type(block)
        for pin in block.pins():
            bpin2node, _track2node = node_index
            pin_node_xml = bpin2node[(block, pin)]
            pin_side = g.single_element(pin_node_xml, 'loc').get('side')

            track = tracks[pin_side]
            if verbose:
                print("Connecting block %s to track %s " % (block, track))
            g.connect_pin_to_track(
                block, pin, track, switch, node_index=node_index)

    print("Indexing nodes")
    node_index = g.index_node_objects()
    # TODO: clean this section up to be more generic
    # only top/bottom in this design
    print("Skipping connecting block pins to CHANX")
    # All the pins are either on the right
    print("Connecting left-right block pins to CHANY")
    for x in range(0, grid_sz.width - 0):
        for tracki in range(rcw):
            # channel should run the entire length
            tracks = {}
            if x != 0:
                tracks['LEFT'] = g.channels.y.column(x - 1)[1][tracki]
            if x != grid_sz.width - 1:
                tracks['RIGHT'] = g.channels.y.column(x)[1][tracki]
            # Now bind to all adjacent pins
            for block in g.block_grid.blocks_for(col=x):
                connect_block_to_track(block, tracks, node_index=node_index)


def connect_tracks_to_tracks(g, switch, verbose=False):
    print("Connecting tracks to tracks")
    node_index = g.index_node_objects()

    # Iterate over all valid x channels and connect to all valid y channels and vice versa as direction implies
    for xtrack in g.channels.x.tracks():
        for ytrack in g.channels.y.tracks():

            def try_connect(atrack, btrack):
                # One of the nodes should be going in and the other should be going out
                # Filter out grossly non-sensical connections that confuse the VPR GUI
                if (btrack.direction == channel.Track.Direction.INC
                        and btrack.start0 <= atrack.common
                        or btrack.direction == channel.Track.Direction.DEC
                        and btrack.start0 > atrack.common):
                    g.connect_track_to_track(
                        btrack, atrack, switch, node_index=node_index)
                    if verbose:
                        print("Connect %s to %s" % (btrack, atrack))

            try_connect(xtrack, ytrack)
            try_connect(ytrack, xtrack)


def print_nodes_edges(g):
    print("Edges: %d (index: %d)" % (len(g.ids._xml_edges),
                                     len(g.ids.id2node['edge'])))
    print("Nodes: %d (index: %d)" % (len(g.ids._xml_nodes),
                                     len(g.ids.id2node['node'])))


def rebuild_graph(fn, fn_out, rcw=6, verbose=False):
    '''
    Add rcw tracks spanning full channel to both X and Y channels
    Connect all of those to all the adjacent pins
    Fully connect tracks at intersections
    For intersections this means we actually have two edges per intersection
    since source and sink must be specified
    '''

    print('Importing input g')
    g = g.Graph(rr_graph_file=fn, verbose=verbose)
    # g.print_graph(g, verbose=False)
    print('Source g loaded')
    print_nodes_edges(g)
    grid_sz = g.block_grid.size()
    print("Grid size: %s" % (grid_sz, ))
    print('Exporting pin placement')
    sides = g.pin_sidesf()

    print()

    # Remove existing rr_graph
    print('Clearing nodes and edges')
    g.ids.clear_graph()
    print('Clearing channels')
    g.channels.clear()
    print('Cleared original g')
    print_nodes_edges(g)

    print()

    print('Creating switches')
    # Create a single switch type to use for all connections
    switch = g.ids.add_switch('switchblade', buffered=1)
    print('Rebuilding block I/O nodes')
    g.add_nodes_for_blocks(switch, sides)
    print_nodes_edges(g)

    print()

    create_tracks(g, grid_sz, rcw, verbose=verbose)
    print()
    connect_blocks_to_tracks(g, grid_sz, rcw, switch)
    print()
    connect_tracks_to_tracks(g, switch, verbose=verbose)
    print()
    print("Completed rebuild")
    print_nodes_edges(g)

    if fn_out:
        print('Writing to %s' % fn_out)
        open(fn_out, 'w').write(
            ET.tostring(g.to_xml(), pretty_print=True).decode('ascii'))
    else:
        print("Printing")
        print(ET.tostring(g.to_xml(), pretty_print=True).decode('ascii'))

    return g


def main():
    import argparse

    parser = argparse.ArgumentParser()
    parser.add_argument("--verbose", action='store_true')
    parser.add_argument("--route_chan_width", type=int, default=6)
    parser.add_argument("rr_graph_in")
    parser.add_argument("rr_graph_out", nargs='?')
    args = parser.parse_args()

    fn = args.rr_graph_in
    fn_out = args.rr_graph_out

    rebuild_graph(fn, fn_out, rcw=args.route_chan_width, verbose=args.verbose)


if __name__ == "__main__":
    main()
