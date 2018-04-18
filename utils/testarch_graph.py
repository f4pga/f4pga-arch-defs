import lib.rr_graph.graph as graph
import sys
import lxml.etree as ET
import os

def rebuild_graph(fn):
    '''
    Recreate the original test device rr_graph using our API
    '''
    print('Rebuild: parsing original')
    g = graph.Graph(rr_graph_file=fn)
    graph.print_graph(g, verbose=False)

    print('Rebuild: clearing')
    #assert 0
    # Remove existing rr_graph
    g.ids.clear_graph()
    graph.print_graph(g)

    print('Rebuild: adding nodes')
    '''
    <node id="0" type="SOURCE" capacity="1">
            <loc xlow="1" ylow="1" xhigh="1" yhigh="1" ptc="0"/>
            <timing R="0" C="0"/>
    </node>
    '''
    for block in g.block_graph:
        print(block)
        g.ids.add_nodes_for_block(block)
    print
    graph.print_graph(g)

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

