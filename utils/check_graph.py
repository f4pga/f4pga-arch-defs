#!/usr/bin/env python3

import argparse
from lxml import etree
from lib.rr_graph import graph
from lib.rr_graph import inaccessible


def check_graph(rr_graph_file):
    '''
    Check that the rr_graph has connections from all SOURCE nodes to all SINK nodes.
    '''
    print('Loading graph.')
    xml_graph = etree.parse(rr_graph_file, etree.XMLParser(remove_blank_text=True))
    routing_graph = graph.RoutingGraph(xml_graph, verbose=True, clear_fabric=False)
    print('Checking if all source nodes connect to all sink nodes.')
    inaccessible_nodes = inaccessible.inaccessible_sink_node_ids_by_source_node_id(routing_graph)
    if inaccessible_nodes:
        print('FAIL')
        for source_id, sink_ids in inaccessible_nodes.items():
            print('Node {} does not connect to nodes {}.'.format(source_id, sink_ids))
    else:
        print('SUCCESS')


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('rr_graph_file', type=str)
    args = parser.parse_args()
    check_graph(args.rr_graph_file)


if __name__ == '__main__':
    main()
