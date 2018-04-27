import lib.rr_graph.graph as graph
import lib.rr_graph.channel as channel
from lib.rr_graph import Position

import sys
import lxml.etree as ET
import os

# all tracks go in one direction
def create_tracks_uni(g, grid_sz, rcw):
    print("Creating tracks, channel width: %d" % rcw)
    print("Block grid size: %s" % (g.block_grid.size,))
    print("Channel grid size: %s" % (g.channels.size,))
    segment = channel.Segment(0, 'awesomesauce', timing_r=420, timing_c='3.e-14')
    # FIXME: should alternate INC/DEC
    # chanx going entire width
    for y in range(0, grid_sz.height - 1):
        print()
        for tracki in range(rcw):
            track, _track_node = g.create_xy_track((1, y), (grid_sz.width - 2, y), segment)
            assert tracki == track.idx, 'Expect index %s, got %s' % (tracki, track.idx)
            print("Create track %s" % (track,))
    g.channels.x.assert_width(rcw)
    g.channels.x.assert_full()
    # chany going entire height
    for x in range(0, grid_sz.width - 1):
        print()
        for tracki in range(rcw):
            track, _track_node = g.create_xy_track((x, 1), (x, grid_sz.height - 2), segment)
            assert tracki == track.idx, 'Expect index %s, got %s' % (tracki, track.idx)
            print("Create track %s" % (track,))
    g.channels.y.assert_width(rcw)
    g.channels.y.assert_full()

# bi-directional channels
def create_tracks(g, grid_sz, rcw):
    print("Creating tracks, channel width: %d" % rcw)
    print("Block grid size: %s" % (g.block_grid.size,))
    print("Channel grid size: %s" % (g.channels.size,))
    assert rcw % 2 == 0

    segment = channel.Segment(0, 'awesomesauce', timing_r=420, timing_c='3.e-14')
    def alt_pos(begin, end, swap):
        if swap:
            return end, begin, channel.Track.Direction.DEC
        else:
            return begin, end, channel.Track.Direction.INC
    # FIXME: should alternate INC/DEC
    # chanx going entire width
    for y in range(0, grid_sz.height - 1):
        print()
        for tracki in range(rcw):
            begin, end, direction = alt_pos((1, y), (grid_sz.width - 2, y), tracki % 2 == 1)
            track, _track_node = g.create_xy_track(begin, end, segment,
                                                   type=channel.Track.Type.X, direction=direction)
            assert tracki == track.idx, 'Expect index %s, got %s' % (tracki, track.idx)
            print("Create track %s" % (track,))
    g.channels.x.assert_width(rcw)
    g.channels.x.assert_full()
    # chany going entire height
    for x in range(0, grid_sz.width - 1):
        print()
        for tracki in range(rcw):
            begin, end, direction = alt_pos((x, 1), (x, grid_sz.height - 2), tracki % 2 == 1)
            track, _track_node = g.create_xy_track(begin, end, segment,
                                                   type=channel.Track.Type.Y, direction=direction)
            assert tracki == track.idx, 'Expect index %s, got %s' % (tracki, track.idx)
            print("Create track %s" % (track,))
    g.channels.y.assert_width(rcw)
    #g.channels.y.assert_full()

def connect_blocks_to_tracks(g, grid_sz, rcw, switch):
    # FIXME: performance issue here (takes a couple seconds on my machine)
    # Will likely run into issues on real devices

    def connect_block_to_track(block, trackl, trackr, node_index=None):
        '''Connect all block pins to given track'''
        assert type(block) is graph.Block, type(block)
        #print("Block to track: %s <=> %s" % (block.position, track))
        for pin in block.pins():
            bpin2node, _track2node = node_index
            pin_node_xml = bpin2node[(block, pin)]
            pin_side = channel.node_loc(pin_node_xml).get('side')

            if pin_side == 'LEFT':
                print('left')
                g.connect_pin_to_track(block, pin, trackl, switch, node_index=node_index)
            elif pin_side == 'RIGHT':
                print('right')
                g.connect_pin_to_track(block, pin, trackr, switch, node_index=node_index)
            else:
                assert False, pin_side
            #g.index_node_objects()

    print("Indexing")
    node_index = g.index_node_objects()
    '''
    print("Connecting blocks to CHANX")
    for y in range(0, grid_sz.height - 2):
        #print()
        #print("CHANX Y=%d" % y)
        for tracki in range(rcw):
            # channel should run the entire length
            track = g.channels.x.row(y)[0][tracki]
            assert track is not None
            # Now bind to all adjacent pins
            for block in g.block_grid.blocks_for(row=y):
                connect_block_to_track(block, track, node_index=node_index)
    '''
    # All the pins are either on the right
    print("Connecting blocks to CHANY")
    for x in range(0, grid_sz.width - 0):
        for tracki in range(rcw):
            #print(x, tracki)
            # channel should run the entire length
            trackl = None
            trackr = None
            if x != 0:
                trackl = g.channels.y.column(x - 1)[1][tracki]
            if x != grid_sz.width - 1:
                trackr = g.channels.y.column(x)[1][tracki]
            #assert trackr is not None
            # Now bind to all adjacent pins
            for block in g.block_grid.blocks_for(col=x):
                print("Connecting block %s to track %s "% (block, trackr))
                connect_block_to_track(block, trackl, trackr, node_index=node_index)

def connect_tracks_to_tracks(g, grid_sz, switch):
    print("Connecting tracks to tracks")
    node_index = g.index_node_objects()

    # a few manual connections
    # make lower right connection only
    # chan y at (x=0, y=1) to chanx at (x=1, y=0)
    if 0:
        rcw = 2
        for trackix in range(rcw):
            for trackiy in range(rcw):
                xtrack = g.channels.x[Position(1, 0)][trackix]
                ytrack = g.channels.y[Position(0, 1)][trackiy]
                g.connect_track_to_track_bidir(xtrack, ytrack, switch, node_index=node_index)

        for trackix in range(rcw):
            for trackiy in range(rcw):
                xtrack = g.channels.x[Position(2, 0)][trackix]
                ytrack = g.channels.y[Position(1, 1)][trackiy]
                g.connect_track_to_track_bidir(xtrack, ytrack, switch, node_index=node_index)


        xtrack = g.channels.x[Position(1, 1)][0]
        ytrack = g.channels.y[Position(0, 1)][0]
        g.connect_track_to_track_bidir(xtrack, ytrack, switch, node_index=node_index)

    # github issue config
    # https://github.com/verilog-to-routing/vtr-verilog-to-routing/issues/335
    if 0:
        # Iterate over all valid x channels and connect to all valid y channels and vice versa as direction implies
        for xtrack in g.channels.x.tracks():
            for ytrack in g.channels.y.tracks():
                if not (xtrack.common == 1 and xtrack.idx == 1):
                    continue
                if not (ytrack.common == 1 and ytrack.idx == 1):
                    continue
                g.connect_track_to_track_bidir(xtrack, ytrack, switch, node_index=node_index)
                print("Connect %s to %s" % (xtrack, ytrack))

    # Iterate over all valid x channels and connect to all valid y channels and vice versa as direction implies
    for xtrack in g.channels.x.tracks():
        for ytrack in g.channels.y.tracks():
            def try_connect(atrack, btrack):
                # One of the nodes should be going in and the other should be going out
                # Filter out grossly non-sensical connections that confuse the VPR GUI
                if (btrack.direction == channel.Track.Direction.INC and btrack.start0 <= atrack.common
                        or btrack.direction == channel.Track.Direction.DEC and btrack.start0 > atrack.common):
                    g.connect_track_to_track(btrack, atrack, switch, node_index=node_index)
                    print("Connect %s to %s" % (btrack, atrack))
            try_connect(xtrack, ytrack)
            try_connect(ytrack, xtrack)


def rebuild_graph(fn, fn_out, rcw=6):
    '''
    Add N tracks to each X and Y
    Connect all of those to all the adjacent pins
    Fully connect tracks at intersections
    For intersections this means we actually have two edges per intersection
    since source and sink must be specified

     ___ I  | | |
    |   |-<-*-*-*
    |   |O  | | |
    |___|->-*-*-*
            | | |
            | | |
    --------*-*-*---
            | | |
    --------*-*-*---
            | | |
    --------*-*-----
            | | |
     ___ I  | | |
    |   |-<-*-*-*
    |   |O  | | |
    |___|->-*-*-*
            | | |
    '''

    print('Rebuild: parsing original')
    g = graph.Graph(rr_graph_file=fn)
    graph.print_graph(g, verbose=False)

    print('Rebuild: clearing')
    #assert 0
    # Remove existing rr_graph
    g.ids.clear_graph()
    g.channels.clear()
    graph.print_graph(g)

    # Create a single switch type to use for all connections
    switch = g.ids.add_switch('switchblade', buffered=1)

    print('Rebuild: adding nodes')
    g.add_nodes_for_blocks(switch)
    print
    graph.print_graph(g)

    grid_sz = g.block_grid.size()
    print("Grid size: %s" % (grid_sz,))
    print()
    create_tracks(g, grid_sz, rcw)
    print()
    connect_blocks_to_tracks(g, grid_sz, rcw, switch)
    print()
    connect_tracks_to_tracks(g, grid_sz, switch)

    print("Printing")
    print("Edges: %d (index: %d)" % (len(g.ids._xml_edges), len(g.ids.id2node['edge'])))
    print("Nodes: %d (index: %d)" % (len(g.ids._xml_nodes), len(g.ids.id2node['node'])))
    #for id, node in g.ids.id2node['edge'].items():
    #    print("edge %d: %s" % (id, ET.tostring(node)))

    if fn_out:
        open(fn_out, 'w').write(ET.tostring(g.to_xml(), pretty_print=True).decode('ascii'))
    else:
        print(ET.tostring(g.to_xml(), pretty_print=True).decode('ascii'))

    return g

def redump_graph(fn):
    print('Loading graph')
    g = graph.Graph(rr_graph_file=fn)
    print('Converting to XML')
    e = g.to_xml()
    print('Dumping')
    print(ET.tostring(e, pretty_print=True).decode('ascii'))
    #print(ET.tostring(e, pretty_print=True, encoding='utf-8'))

def main():
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument("--route_chan_width", type=int, default=6)
    parser.add_argument("rr_graph_in")
    parser.add_argument("rr_graph_out", nargs='?')
    args = parser.parse_args()

    fn = args.rr_graph_in
    fn_out = args.rr_graph_out

    if 1:
        rebuild_graph(fn, fn_out, rcw=args.route_chan_width)
    if 0:
        redump_graph(fn)

    if 0:
        bt = graph.BlockType(name="BLK_IG-IBUF")
        xml_string1 = '''
            <pin_class type="OUTPUT">
                <pin index="0" ptc="0">BLK_IG-IBUF.I[0]</pin>
            </pin_class>
            '''
        pc = graph.Pin.Class.from_xml(bt, ET.fromstring(xml_string1))

    print('Exiting')

if __name__ == "__main__":
    main()

