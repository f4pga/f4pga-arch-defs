#!/usr/bin/env python3

import argparse
from lxml import etree
from lib.rr_graph import graph


def inaccessible_node_ids(forward_connections, node_id, target_node_ids):
    """
    Takes a mapping of forward connectionso from nodes, a starting `node_id` and
    a set of all the target node ids for which we want to check routability.
    Returns a set of all the target node ids that are not accessible from `node_id`.
    """
    layer = [node_id]
    visited = set()
    layer_index = 0
    while layer:
        layer_index += 1
        new_layer = set()
        for this_node_id in layer:
            new_layer |= forward_connections[this_node_id]
        new_layer -= visited
        visited |= new_layer
        layer = new_layer
    return target_node_ids - visited


def routing_graph_to_dictionary(routing_graph):
    edges_by_node = routing_graph.edges_for_allnodes()
    dict_graph = {}
    for node in routing_graph._xml_parent(graph.RoutingNode):
        node_id = int(node.get('id'))
        dest_ids = set()
        for edge in edges_by_node[node_id]:
            if int(edge.get('src_node')) == node_id:
                dest_ids.add(int(edge.get('sink_node')))
        dict_graph[node_id] = dest_ids
    return dict_graph


def inaccessible_sink_node_ids_by_source_node_id(routing_graph):
    """
    Returns a dictionary that maps source node ids to sets of sink node ids
    which are inaccessible to them.
    If a source node id can access all sink nodes it is not present in the
    returned dictionary.
    """
    # First convert the graph to a dictionary.
    cyclic_graph = routing_graph_to_dictionary(routing_graph)
    source_node_ids = set([
        int(node.get('id')) for node in routing_graph._xml_parent(graph.RoutingNode)
        if node.get('type') == 'SOURCE'])
    sink_node_ids = set([
        int(node.get('id')) for node in routing_graph._xml_parent(graph.RoutingNode)
        if node.get('type') == 'SINK'])
    inaccessible_by_source_node = {}
    total = len(source_node_ids)
    for index, source_node_id in enumerate(source_node_ids):
        inaccessible_ids = inaccessible_node_ids(
            cyclic_graph, source_node_id,
            target_node_ids=sink_node_ids)
        if inaccessible_ids:
            inaccessible_by_source_node[source_node_id] = inaccessible_ids
        if index % 100 == 0:
            print('Checked {}/{} source nodes'.format(index, total))
    return inaccessible_by_source_node

def check_graph(rr_graph_file):
    '''
    Check that the rr_graph has connections from all SOURCE nodes to all SINK nodes.
    '''
    print('Parsing XML')
    xml_graph = etree.parse(rr_graph_file, etree.XMLParser(remove_blank_text=True))
    print('Creating a routing graph')
    routing_graph = graph.RoutingGraph(xml_graph, verbose=True, clear_fabric=False)
    print('Checking if all source nodes connect to all sink nodes.')
    inaccessible_nodes = inaccessible_sink_node_ids_by_source_node_id(routing_graph)
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
