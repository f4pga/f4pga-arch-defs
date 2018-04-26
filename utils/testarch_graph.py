import lib.rr_graph.graph as graph
import lib.rr_graph.channel as channel
from lib.rr_graph import Position

import sys
import lxml.etree as ET
import os

def create_tracks(g, grid_sz, rcw):
    print("Creating tracks, channel width: %d" % rcw)
    segment = channel.Segment(0, 'awesomesauce', timing_r=420, timing_c='3.e-14')
    # FIXME: should alternate INC/DEC
    # chanx going entire width
    for y in range(grid_sz.height):
        print()
        for tracki in range(rcw):
            track, _track_node = g.create_xy_track((0, y), (grid_sz.width - 1, y), segment)
            assert tracki == track.idx, 'Expect index %s, got %s' % (tracki, track.idx)
            print("Create track %s" % (track,))
    g.channels.x.assert_width(rcw)
    g.channels.x.assert_full()
    # chany going entire height
    for x in range(grid_sz.width):
        print()
        for tracki in range(rcw):
            track, _track_node = g.create_xy_track((x, 0), (x, grid_sz.height - 1), segment)
            assert tracki == track.idx, 'Expect index %s, got %s' % (tracki, track.idx)
            print("Create track %s" % (track,))
    g.channels.y.assert_width(rcw)
    g.channels.y.assert_full()

def connect_blocks_to_tracks(g, grid_sz, rcw, switch):
    # FIXME: performance issue here (takes a couple seconds on my machine)
    # Will likely run into issues on real devices

    def connect_block_to_track(block, track, node_index=None):
        '''Connect all block pins to given track'''
        assert type(block) is graph.Block, type(block)
        #print("Block to track: %s <=> %s" % (block.position, track))
        for pin in block.pins():
            g.connect_pin_to_track(block, pin, track, switch, node_index=node_index)
            g.index_node_objects()

    print("Indexing")
    node_index = g.index_node_objects()
    print("Connecting blocks to CHANX")
    for y in range(grid_sz.height):
        #print()
        #print("CHANX Y=%d" % y)
        for tracki in range(rcw):
            # channel should run the entire length
            track = g.channels.x.row(y)[0][tracki]
            # Now bind to all adjacent pins
            for block in g.block_graph.blocks_for(row=y):
                connect_block_to_track(block, track, node_index=node_index)
    print("Connecting blocks to CHANY")
    for x in range(grid_sz.width):
        for tracki in range(rcw):
            # channel should run the entire length
            track = g.channels.y.column(x)[0][tracki]
            # Now bind to all adjacent pins
            for block in g.block_graph.blocks_for(col=x):
                connect_block_to_track(block, track, node_index=node_index)

def connect_tracks_to_tracks(g, grid_sz, switch):
    node_index = g.index_node_objects()
    print("Connecting tracks to tracks")
    # Now connect tracks together
    for y in range(grid_sz.height):
        for x in range(grid_sz.width):
            xtracks = g.channels.x[Position(x, y)]
            ytracks = g.channels.y[Position(x, y)]
            # Add bi-directional links between all permutations
            for xtrack in xtracks:
                for ytrack in ytracks:
                    g.connect_track_to_track(xtrack, ytrack, switch, node_index=node_index)

def rebuild_graph(fn, fn_out):
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
    # ala --route_chan_width
    rcw = 6

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

    grid_sz = g.block_graph.block_grid_size()
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
    parser.add_argument("rr_graph_in")
    parser.add_argument("rr_graph_out", nargs='?')
    args = parser.parse_args()

    fn = args.rr_graph_in
    fn_out = args.rr_graph_out

    if 1:
        rebuild_graph(fn, fn_out)
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

