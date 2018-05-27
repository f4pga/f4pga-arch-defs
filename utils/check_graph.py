#!/usr/bin/env python3

import argparse
from lxml import etree
from lib.rr_graph import graph
from lib.rr_graph import cyclic_to_acyclic


def inaccessible_node_ids(forward_connections, node_id, target_node_ids, cache):
    """
    Takes a `node_id` and a set of all the target node ids for which we want to check
    routability.
    `cache` is a dictionary for storing results of this function call.
    The graph must be acyclic.
    Returns a set of all the target node ids that are not accessible from `node_id`.
    """
    # Put a 'None' in the cache to mark that we're processing this.
    # That way we can detect loops.
    cache[node_id] = None
    # Initially start assuming all sink nodes are inaccessible.
    inaccessible = set(target_node_ids)
    if node_id in inaccessible:
        inaccessible.remove(node_id)
    for dest_node_id in forward_connections[node_id]:
        assert dest_node_id != node_id
        # Confirm that there is not a loop.
        assert (dest_node_id not in cache) or (cache[dest_node_id] is not None)
        inaccessible &= inaccessible_node_ids(forward_connections, dest_node_id, target_node_ids, cache=cache)
    cache[node_id] = inaccessible
    return inaccessible


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
    acyclic_graph, node_to_cyclesea = cyclic_to_acyclic.cyclic_to_acyclic(cyclic_graph)
    source_node_ids = set([
        int(node.get('id')) for node in routing_graph._xml_parent(graph.RoutingNode)
        if node.get('type') == 'SOURCE'])
    sink_node_ids = set([
        int(node.get('id')) for node in routing_graph._xml_parent(graph.RoutingNode)
        if node.get('type') == 'SINK'])
    assert not (source_node_ids & set(node_to_cyclesea.keys()))
    assert not (sink_node_ids & set(node_to_cyclesea.keys()))

    inaccessible_by_source_node = {}
    cache = {}
    for source_node_id in source_node_ids:
        inaccessible_ids = inaccessible_node_ids(
            acyclic_graph, source_node_id,
            target_node_ids=sink_node_ids, cache=cache)
        if inaccessible_ids:
            inaccessible_by_source_node[source_node_id] = inaccessible_ids
    return inaccessible_by_source_node


def test_simple():
    '''
    Test a simple graph without complete connectivity.
    '''
    expected_inaccessible = {7: {6}}
    rr_graph_string = '''
<rr_graph>
    <!--
              7
              |
              V
    0 -> 1 -> 2 -> 3
         |
         V
         4 -> 5 -> 6
    -->
  <rr_nodes>
    <node id="0" type="SOURCE"/>
    <node id="1" type="WHATEVER"/>
    <node id="2" type="WHATEVER"/>
    <node id="3" type="SINK"/>
    <node id="4" type="WHATEVER"/>
    <node id="5" type="WHATEVER"/>
    <node id="6" type="SINK"/>
    <node id="7" type="SOURCE"/>
  </rr_nodes>
  <rr_edges>
    <edge src_node="0" sink_node="1"/>
    <edge src_node="1" sink_node="2"/>
    <edge src_node="2" sink_node="3"/>
    <edge src_node="1" sink_node="4"/>
    <edge src_node="4" sink_node="5"/>
    <edge src_node="5" sink_node="6"/>
    <edge src_node="7" sink_node="2"/>
  </rr_edges>
</rr_graph>
    '''
    xml_graph = etree.XML(rr_graph_string)
    routing_graph = graph.RoutingGraph(xml_graph, verbose=True, clear_fabric=False)
    inaccessible = inaccessible_sink_node_ids_by_source_node_id(routing_graph)
    assert inaccessible == expected_inaccessible


def test_loop():
    '''
    Test a graph with a loop.
    '''
    expected_inaccessible = {0: {9},
                             7: {9},
                             8: {3, 6}}
    rr_graph_string = '''
<rr_graph>
    <!--
              7
              |
              V
    0 -> 1 <- 2 -> 3
         |    ^
         V    |
         4 -> 5 -> 6

    8 -> 9
    -->
  <rr_nodes>
    <node id="0" type="SOURCE"/>
    <node id="1" type="WHATEVER"/>
    <node id="2" type="WHATEVER"/>
    <node id="3" type="SINK"/>
    <node id="4" type="WHATEVER"/>
    <node id="5" type="WHATEVER"/>
    <node id="6" type="SINK"/>
    <node id="7" type="SOURCE"/>
    <node id="8" type="SOURCE"/>
    <node id="9" type="SINK"/>
  </rr_nodes>
  <rr_edges>
    <edge src_node="0" sink_node="1"/>
    <edge src_node="2" sink_node="1"/>
    <edge src_node="2" sink_node="3"/>
    <edge src_node="1" sink_node="4"/>
    <edge src_node="4" sink_node="5"/>
    <edge src_node="5" sink_node="6"/>
    <edge src_node="5" sink_node="2"/>
    <edge src_node="7" sink_node="2"/>
    <edge src_node="8" sink_node="9"/>
  </rr_edges>
</rr_graph>
    '''
    xml_graph = etree.XML(rr_graph_string)
    routing_graph = graph.RoutingGraph(xml_graph, verbose=True, clear_fabric=False)
    inaccessible = inaccessible_sink_node_ids_by_source_node_id(routing_graph)
    assert inaccessible == expected_inaccessible


def test_complex():
    '''
    Test a graph with loops.
    '''
    expected_inaccessible = {0: {14},
                             7: {14},
                             15: {3, 6}}
    rr_graph_string = '''
<rr_graph>
    <!--
              7
              |
              V
    0 -> 1 <- 2 -> 3
         |    ^
         V    |
         4 -> 5 -> 6
              ^
              |
         8 -> 9  -> 10 -> 16
              ^     |     |
              |     V     V
              11 <- 12 -> 13 -> 14
                          ^
                          |
                          15
    -->
  <rr_nodes>
    <node id="0" type="SOURCE"/>
    <node id="1" type="WHATEVER"/>
    <node id="2" type="WHATEVER"/>
    <node id="3" type="SINK"/>
    <node id="4" type="WHATEVER"/>
    <node id="5" type="WHATEVER"/>
    <node id="6" type="SINK"/>
    <node id="7" type="SOURCE"/>
    <node id="8" type="SOURCE"/>
    <node id="9" type="WHATEVER"/>
    <node id="10" type="WHATEVER"/>
    <node id="11" type="WHATEVER"/>
    <node id="12" type="WHATEVER"/>
    <node id="13" type="WHATEVER"/>
    <node id="14" type="SINK"/>
    <node id="15" type="SOURCE"/>
    <node id="16" type="WHATEVER"/>
  </rr_nodes>
  <rr_edges>
    <edge src_node="0" sink_node="1"/>
    <edge src_node="2" sink_node="1"/>
    <edge src_node="2" sink_node="3"/>
    <edge src_node="1" sink_node="4"/>
    <edge src_node="4" sink_node="5"/>
    <edge src_node="5" sink_node="6"/>
    <edge src_node="5" sink_node="2"/>
    <edge src_node="7" sink_node="2"/>
    <edge src_node="8" sink_node="9"/>
    <edge src_node="9" sink_node="5"/>
    <edge src_node="9" sink_node="10"/>
    <edge src_node="10" sink_node="16"/>
    <edge src_node="10" sink_node="12"/>
    <edge src_node="16" sink_node="13"/>
    <edge src_node="11" sink_node="9"/>
    <edge src_node="12" sink_node="11"/>
    <edge src_node="12" sink_node="13"/>
    <edge src_node="13" sink_node="14"/>
    <edge src_node="15" sink_node="13"/>
  </rr_edges>
</rr_graph>
    '''
    xml_graph = etree.XML(rr_graph_string)
    routing_graph = graph.RoutingGraph(xml_graph, verbose=True, clear_fabric=False)
    inaccessible = inaccessible_sink_node_ids_by_source_node_id(routing_graph)
    assert inaccessible == expected_inaccessible


def run_tests():
    test_simple()
    test_loop()
    test_complex()


def check_graph(rr_graph_file):
    '''
    Check that the rr_graph has connections from all SOURCE nodes to all SINK nodes.
    '''
    print('Loading graph.')
    xml_graph = etree.parse(rr_graph_file, etree.XMLParser(remove_blank_text=True))
    routing_graph = graph.RoutingGraph(xml_graph, verbose=True, clear_fabric=False)
    print('Checking if all source nodes connect to all sink nodes.')
    inaccessible = inaccessible_sink_node_ids_by_source_node_id(routing_graph)
    if inaccessible:
        print('FAIL')
        for source_id, sink_ids in inaccessible.items():
            print('Node {} does not connect to nodes {}.'.format(source_id, sink_ids))
    else:
        print('SUCCESS')


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--rr_graph_file', type=str, default=None)
    args = parser.parse_args()
    if args.rr_graph_file:
        check_graph(args.rr_graph_file)
    else:
        print('No graph file passed, so run tests.')
        run_tests()
        print('PASSED')


if __name__ == '__main__':
    main()
