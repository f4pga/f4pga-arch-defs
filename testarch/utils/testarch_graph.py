#!/usr/bin/env python3

import lib.rr_graph.graph as graph
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
                g.segments[0],
                name="CHANX{:04d}@{:04d}".format(y, tracki),
                typeh=channel.Track.Type.X,
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
                g.segments[0],
                name="CHANY{:04d}@{:04d}".format(x, tracki),
                typeh=channel.Track.Type.Y,
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

    def connect_block_to_track(block, tracks):
        """Connect all block pins to given track"""
        assert type(block) is graph.Block, type(block)
        for pin in block.pins:
            pin_node_xml = g.routing.localnames[(block.position, pin.name)]
            pin_side = graph.RoutingNodeSide[graph.single_element(
                pin_node_xml, 'loc').get('side')]

            if pin_side not in tracks:
                print("Skipping {} on {}".format(pin, block))
                continue

            track = tracks[pin_side]
            if verbose:
                print("Connecting block %s to track %s " % (block, track))
            g.connect_pin_to_track(block, pin, track, switch)

    print("Indexing nodes")
    print("Skipping connecting block pins to CHANX")
    print("Connecting left-right block pins to CHANY")
    for x in range(0, grid_sz.width - 0):
        for tracki in range(rcw):
            # channel should run the entire length
            tracks = {}
            if x != 0:
                tracks[graph.RoutingNodeSide.LEFT] = g.channels.y.column(
                    x - 1)[1][tracki]
            if x != grid_sz.width - 1:
                tracks[graph.RoutingNodeSide.RIGHT] = g.channels.y.column(x)[
                    1][tracki]
            # Now bind to all adjacent pins
            for block in g.block_grid.blocks_for(col=x):
                connect_block_to_track(block, tracks)


def connect_tracks_to_tracks(g, switch, verbose=False):
    print("Connecting tracks to tracks")

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
                    g.connect_track_to_track(btrack, atrack, switch)
                    if verbose:
                        print("Connect %s to %s" % (btrack, atrack))

            try_connect(xtrack, ytrack)
            try_connect(ytrack, xtrack)


def print_nodes_edges(g):
    print("Edges: %d (index: %d)" %
          (len(g.routing._xml_parent(graph.RoutingEdge)),
           len(g.routing.id2element[graph.RoutingEdge])))
    print("Nodes: %d (index: %d)" %
          (len(g.routing._xml_parent(graph.RoutingNode)),
           len(g.routing.id2element[graph.RoutingNode])))


def rebuild_graph(fn, fn_out, rcw=6, verbose=False):
    """
    Add rcw tracks spanning full channel to both X and Y channels
    Connect all of those to all the adjacent pins
    Fully connect tracks at intersections
    For intersections this means we actually have two edges per intersection
    since source and sink must be specified
    """

    print('Importing input g')
    g = graph.Graph(rr_graph_file=fn, verbose=verbose, clear_fabric=False)
    # g.print_graph(g, verbose=False)
    print('Source g loaded')
    print_nodes_edges(g)
    grid_sz = g.block_grid.size
    print("Grid size: %s" % (grid_sz, ))
    print('Exporting pin placement')
    pin_sides, pin_offsets = g.extract_pin_meta()

    def get_pin_meta(block, pin):
        return (pin_sides[(block.position, pin.name)], pin_offsets[(block.position, pin.name)])

    print()

    # Remove existing rr_graph
    print('Clearing nodes and edges')
    g.routing.clear()
    print('Clearing channels')
    g.channels.clear()
    print('Cleared original g')
    print_nodes_edges(g)

    print()

    print('Rebuilding block I/O nodes')
    g.create_block_pins_fabric(g.switches['__vpr_delayless_switch__'],
                               get_pin_meta)
    print_nodes_edges(g)

    print()

    create_tracks(g, grid_sz, rcw, verbose=verbose)
    print()
    connect_blocks_to_tracks(g, grid_sz, rcw, g.switches[0])
    print()
    connect_tracks_to_tracks(g, g.switches[0], verbose=verbose)
    print()
    print("Completed rebuild")
    print_nodes_edges(g)

    #short_xml = list(g._xml_graph.iterfind('//switches/switch/[@name="short"]'))[0]
    #short_xml.attrib['configurable'] = '0'
    #short_xml.attrib['buffered'] = '0'
    #print("Rewrote short switch: ", ET.tostring(short_xml))

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
