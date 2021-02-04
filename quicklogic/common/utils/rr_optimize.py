import lib.rr_graph.graph2 as rr

# =============================================================================


def prune_graph(graph):
    """
    Prunes spurious nodes and edges from the graph. Identifies leaf nodes that
    have no outgoing edges and removes them. Identifies root nodes that have
    no incoming edges and removes them. Both removal procedures continue until
    no nodes in question are present.
    """

    # Build maps
    nodes = {node.id : node for node in graph.nodes}
    edges = {i : edge for i, edge in enumerate(graph.edges)}

    # Build edge maps
    edges_from = {}
    edges_to = {}
    for edge_id, edge in edges.items():

        if edge.src_node not in edges_from:
            edges_from[edge.src_node] = set()
        edges_from[edge.src_node].add(edge_id)

        if edge.sink_node not in edges_to:
            edges_to[edge.sink_node] = set()
        edges_to[edge.sink_node].add(edge_id)

    pruned_nodes = 0
    pruned_edges = 0

    # .....................................................

    # Identify leaf nodes (no outgoing edges)
    leafs = set()
    for node in nodes.values():
        if node.id not in edges_from:
            if node.type == rr.NodeType.CHANX or node.type == rr.NodeType.CHANY:
                leafs.add(node.id)

    if len(leafs):
        print("{} leaf channel nodes, prunning...".format(len(leafs)))

    while len(leafs):
        print("", len(leafs))

        # Process leaf nodes
        for leaf_id in set(leafs):

            # Already removed
            if leaf_id not in nodes:
                continue

            # Remove the node
            del nodes[leaf_id]
            leafs.remove(leaf_id)
            pruned_nodes += 1

            # No incoming edges
            if leaf_id not in edges_to:
                continue

            # Get new leaf candidates
            candidates = set()
            for edge_id in edges_to[leaf_id]:
                edge = edges[edge_id]
                if edge.src_node in nodes:
                    node = nodes[edge.src_node]
                    if node.type == rr.NodeType.CHANX or \
                       node.type == rr.NodeType.CHANY:               
                        candidates.add(node.id)

            # Remove the incoming edges from the graph
            for edge_id in edges_to[leaf_id]:
                del edges[edge_id]
                pruned_edges += 1

            del edges_to[leaf_id]

            # Remove incoming edges from new leaf candidates' lists
            for node_id in candidates:
                if node_id in edges_from:

                    for edge_id in set(edges_from[node_id]):
                        if edge_id not in edges:
                            edges_from[node_id].remove(edge_id)

                    # No more outgoing edges
                    if not len(edges_from[node_id]):
                        del edges_from[node_id]

                # Make it a leaf node
                if node_id not in edges_from:
                    leafs.add(node_id)

    # .....................................................

    # Identify unconnected root nodes (no incoming edges)
    roots = set()
    for node in nodes.values():
        if node.id not in edges_to:
            if node.type == rr.NodeType.CHANX or node.type == rr.NodeType.CHANY:
                roots.add(node.id)

    if len(roots):
        print("{} unconnected root channel nodes, prunning...".format(len(roots)))

    while len(roots):
        print("", len(roots))

        # Process leaf nodes
        for root_id in set(roots):

            # Already removed
            if root_id not in nodes:
                continue

            # Remove the node
            del nodes[root_id]
            roots.remove(root_id)
            pruned_nodes += 1

            # No outgoing edges
            if root_id not in edges_from:
                continue

            # Get new leaf candidates
            candidates = set()
            for edge_id in edges_from[root_id]:
                edge = edges[edge_id]
                if edge.sink_node in nodes:
                    node = nodes[edge.sink_node]
                    if node.type == rr.NodeType.CHANX or \
                       node.type == rr.NodeType.CHANY:               
                        candidates.add(node.id)

            # Remove the incoming edges from the graph
            for edge_id in edges_from[root_id]:
                del edges[edge_id]
                pruned_edges += 1

            del edges_from[root_id]

            # Remove outgoing edges from new root candidates' lists
            for node_id in candidates:
                if node_id in edges_to:

                    for edge_id in set(edges_to[node_id]):
                        if edge_id not in edges:
                            edges_to[node_id].remove(edge_id)

                    # No more incoming edges
                    if not len(edges_to[node_id]):
                        del edges_to[node_id]

                # Make it a root node
                if node_id not in edges_to:
                    roots.add(node_id)

    # .....................................................

    # Add nodes and edges back to the graph
    graph.nodes = [node for node in nodes.values()]
    graph.edges = [edge for edge in edges.values()]

    return pruned_nodes, pruned_edges


def reindex_nodes(graph):
    """
    Re-indexes graph nodes so that they are continuous
    """

    print("Re-indexing nodes, updating edges...")

    # Sort nodes by their IDs
    nodes = sorted(list(graph.nodes), key=lambda node: node.id)
    edges = graph.edges
    # Build index map (old -> new)
    index_map = {node.id: i for i, node in enumerate(nodes)}

    # Re-index nodes
    graph.nodes = []
    for node in nodes:

        # Make sure that non-channel nodes have same indices
        if node.type != rr.NodeType.CHANX and node.type != rr.NodeType.CHANY:
            assert node.id == index_map[node.id], node

        fields = node._asdict()
        fields["id"] = index_map[fields["id"]]
        graph.nodes.append(rr.Node(**fields))

    # Re-index edges
    graph.edges = []
    for edge in edges:
        fields = edge._asdict()
        fields["src_node"] = index_map[fields["src_node"]]
        fields["sink_node"] = index_map[fields["sink_node"]]
        graph.edges.append(rr.Edge(**fields))


def optimize_graph(graph):
    """
    Optimizes the rr graph by interatively removing unconnected leaf and root
    nodes until none remain.
    """

    num_nodes = len(graph.nodes)
    num_edges = len(graph.edges)

    while True:

        # Do pruning
        pruned_nodes, pruned_edges = prune_graph(graph)

        # Stop if nothing was pruned
        if pruned_nodes == 0 and pruned_edges == 0:
            break

        print("Pruned {} nodes and {} edges".format(pruned_nodes, pruned_edges))

    print("Pruned total of {} nodes and {} edges".format(
        num_nodes - len(graph.nodes),
        num_edges - len(graph.edges)
    ))

    # Reindex
    reindex_nodes(graph)
