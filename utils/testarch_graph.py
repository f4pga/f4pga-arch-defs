import lib.rr_graph.graph as graph
from lib.rr_graph import Position

import sys
import lxml.etree as ET
import os

def rebuild_graph(fn):
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
    graph.print_graph(g)

    # Create a single switch type to use for all connections
    switch = g.ids.add_switch(buffered=1)
    #switch_id = int(switch.get("id"))

    print('Rebuild: adding nodes')
    g.index_node_objects()
    '''
    <node id="0" type="SOURCE" capacity="1">
            <loc xlow="1" ylow="1" xhigh="1" yhigh="1" ptc="0"/>
            <timing R="0" C="0"/>
    </node>
    '''
    for block in g.block_graph:
        print(block)
        g.ids.add_nodes_for_block(block, switch)
        g.index_node_objects()
    print
    graph.print_graph(g)
    g.index_node_objects()

    # ala --route_chan_width
    rcw = 4


    def connect_block_to_track(block, track, node_index=None):
        '''Connect all block pins to given track'''
        assert type(block) is graph.Block, type(block)
        print("Block to track: %s <=> %s" % (block.position, track))
        for pin in block.pins():    
            g.connect_pin_to_track(block, pin, track, switch, node_index=None)
            g.index_node_objects()

    # currently finding the nodes associated with a pin or pin_class requires exhausive search
    # use this to speed up association
    node_index = g.index_node_objects()

    grid_sz = g.block_graph.block_grid_size()
    print("Grid size: %s" % (grid_sz,))
    # chanx going entire width
    for y in range(grid_sz.height):
        print()
        for _tracki in range(rcw):
            track = g.channels.create_xy_track((0, y), (grid_sz.width - 1, y))
            print("Create track %s:%i" % (track, _tracki))
            node_index = g.index_node_objects()
            # Now bind to all adjacent pins
            for block in g.block_graph.blocks_for(row=y):
                connect_block_to_track(block, track, node_index=node_index)
    # chany going entire height
    for x in range(grid_sz.width):
        for _tracki in range(rcw):
            track = g.channels .create_xy_track((x, 0), (x, grid_sz.height - 1))
            node_index = g.index_node_objects()
            # Now bind to all adjacent pins
            for block in g.block_graph.blocks_for(col=x):
                connect_block_to_track(block, track, node_index=node_index)

    # Now connect tracks together
    for y in range(grid_sz.height):
        for x in range(grid_sz.width):
            xtracks = g.channels.x[Position(x, y)]
            ytracks = g.channels.y[Position(x, y)]
            # Add bi-directional links between all permutations
            for xtrack in xtracks:
                for ytrack in ytracks:
                    g.connect_track_to_track(xtrack, ytrack, switch, node_index=node_index)

def main():
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument("rr_graph")
    args = parser.parse_args()

    fn = args.rr_graph

    if 1:
        rebuild_graph(fn)
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

