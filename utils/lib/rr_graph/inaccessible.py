#!/usr/bin/env python3

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
