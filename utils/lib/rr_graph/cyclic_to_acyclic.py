class CycleSeas:
    """
    Contains the cycleseas that have been found in the graph so far.

    A cyclesea is a the set of nodes contained in intersecting cycles so
    that all nodes are accessible from one another.
    """

    def __init__(self):
        # A dictionry that maps cyclesea_id to the set of nodes.
        self.cycleseas = {}
        # A dictionary that maps a node_id to the cyclesea index that it is present in.
        self.node_to_cyclesea = {}

    def add_nodes_to_cycleseas(self, new_nodes, possibly_unconnected=True):
        """
        Add a new set of nodes.  This new set of nodes can create a new cyclesea if
        possibly_unconnected is True.  Otherwise it will join onto an existing cyclesea,
        or possibly bridge several cycleseas causing them to combine into a new
        cyclesea.
        """
        # Determine which existing cycleseas this set of nodes touchs.
        touching_cycleseas = set()
        for node_id in new_nodes:
            if node_id in self.node_to_cyclesea:
                touching_cycleseas.add(self.node_to_cyclesea[node_id])
        if not possibly_unconnected:
            assert touching_cycleseas
        if touching_cycleseas:
            # Combine the touched cycleseas into a new cyclesea.
            new_cyclesea_id = min(touching_cycleseas)
            old_cyclesea_ids = [cyclesea_id for cyclesea_id in touching_cycleseas
                                if cyclesea_id != new_cyclesea_id]
            for old_cyclesea_id in old_cyclesea_ids:
                self.cycleseas[new_cyclesea_id] |= self.cycleseas[old_cyclesea_id]
                del self.cycleseas[old_cyclesea_id]
            self.cycleseas[new_cyclesea_id] |= new_nodes
        else:
            # Create a new cyclesea
            new_cyclesea_id = min(new_nodes)
            self.cycleseas[new_cyclesea_id] = new_nodes
        # Update the node to cyclesea mapping.
        for node_id in self.cycleseas[new_cyclesea_id]:
            self.node_to_cyclesea[node_id] = new_cyclesea_id

    def add_cycleseas(self, cycleseas):
        '''
        Add in a new set of cycleseas.
        There should be no overlap.
        '''
        for cyclesea_id, node_ids in cycleseas.cycleseas.items():
            assert cyclesea_id not in self.cycleseas
            self.cycleseas[cyclesea_id] = node_ids
        self.node_to_cyclesea.update(cycleseas.node_to_cyclesea)


def find_cycleseas(path, mapping, visited, stopping_nodes, cycleseas):
    """
    Recursively searchs for cycleseas in a graph.
    Doesn't return anything.  Just updates objects in place.

    Arguments:
      `path` is a list of the nodes passed to reach this node.
      `mapping` maps node indices to a set of node indices to which they are forwards connected.
      `stopping_nodes` is a set of nodes at which we should stop traversal.
      `cycleseas` is a collection of the cycleseas that have been found so far.

    0 -> 1 -> 2 -> 3
         ^    |
         |    V
         4 <- 5
    >>> mapping = {0: [1], 1: [2], 2: [3, 5], 3: [], 4: [1], 5: [4]}
    >>> cycleseas = CycleSeas()
    >>> find_cycleseas([0], mapping, set(), set(), cycleseas)
    >>> len(cycleseas.cycleseas)
    1
    >>> sorted(cycleseas.cycleseas[1])
    [1, 2, 4, 5]

              8 <- 9 <- 10
              |         ^
              V         |
    0 -> 1 -> 2 -> 3 -> 7 -> 11
         ^         |    |
         |         V    V
         4 <- 5 <- 6 <- 12
    >>> mapping2 = {0: [1], 1: [2], 2: [3], 3: [6, 7],
    ...             4: [1], 5: [4], 6: [5], 7: [10, 12],
    ...             8: [2], 9: [8], 10: [9], 11: [],
    ...             12: [6]}
    >>> cycleseas2 = CycleSeas()
    >>> find_cycleseas([0], mapping2, set(), set(), cycleseas2)
    >>> len(cycleseas2.cycleseas)
    1
    >>> sorted(cycleseas2.cycleseas[1])
    [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 12]
    """
    node_id = path[-1]
    visited.add(node_id)
    for dest_id in mapping[node_id]:
        assert node_id != dest_id
        if dest_id in stopping_nodes:
            pass
        elif dest_id in path:
            # We've intercepted the path we're on.
            # That means we've found a cyclesea entirely within our path.
            path_index = path.index(dest_id)
            cycleseas.add_nodes_to_cycleseas(set(path[path_index:]), possibly_unconnected=True)
        elif dest_id in visited:
            if dest_id in cycleseas.node_to_cyclesea:
                # We've intercepted a cyclesea.
                # If this cyclesea intercepts somewhere earlier in this path then
                # we add this section of the path to that cyclesea.
                cyclesea_id = cycleseas.node_to_cyclesea[dest_id]
                path_overlap = cycleseas.cycleseas[cyclesea_id] & set(path)
                if path_overlap:
                    path_index = min([path.index(node_id) for node_id in path_overlap])
                    cycleseas.add_nodes_to_cycleseas(
                        set(path[path_index:]), possibly_unconnected=False)
        else:
            path.append(dest_id)
            find_cycleseas(path, mapping, visited, stopping_nodes, cycleseas)
            path.pop()


def cyclic_to_acyclic(mapping):
    '''
    Takes a mapping of node_id to node_ids which are connected to forwards.

    Returns a modified mapping.  Groups of nodes (termed cycleseas here) that can all access
    each other (i.e. are a group of connected loops) are collapsed into a single node, and
    a mapping based on that reduction is returned.  The id used for a cyclesea is the minimum
    index of all the nodes it contains.

    The mapping from node to cyclesea is also returned.

    0 -> 1 -> 2 -> 3
         ^    |
         |    V
         4 <- 5

    We expect nodes {1, 2, 4, 5} to be collapsed into a cyclesea with id=1.

    >>> mapping = {0: [1], 1: [2], 2: [3, 5], 3: [], 4: [1], 5: [4]}
    >>> cyclic_to_acyclic(mapping) == ({0: {1}, 1: {3}, 3: set()}, {1: 1, 2: 1, 4: 1, 5:1})
    True

    0 -> 1 -> 2 -> 3 -> 6 -> 7 -> 8
         ^    |    |    ^    |
         |    V    V    |    V
         4 <- 5    9 -> 10<- 11

    We expect nodes {1, 2, 4, 5} to be collapsed into a cyclesea with id=1 and
              nodes {6, 7, 10, 11} to be collapsed into a cycleesa with id=6.

    >>> mapping2 = {0: [1], 1: [2], 2: [3, 5], 3: [6, 9],
    ...             4: [1], 5: [4], 6: [7], 7: [8, 11],
    ...             8: [], 9: [10], 10: [6], 11: [10]}
    >>> cyclic_to_acyclic(mapping2) == ({0: {1}, 1: {3}, 3: {6, 9}, 6: {8}, 8: set(), 9: {6} },
    ...                                 {1: 1, 2: 1, 4: 1, 5: 1, 6: 6, 7: 6, 11: 6, 10: 6})
    True

    0 -> 1 -> 2 -> 3
         ^    |
         |    V
         4 <- 5

    6 -> 7

    We expect nodes {1, 2, 4, 5} to be collapsed into a cyclesea with id=1.

    >>> mapping = {0: [1], 1: [2], 2: [3, 5], 3: [], 4: [1], 5: [4], 6: [7], 7: []}
    >>> cyclic_to_acyclic(mapping) == ({0: {1}, 1: {3}, 3: set(), 6: {7}, 7: set()},
    ...                                {1: 1, 2: 1, 4: 1, 5: 1})
    True

    '''
    visited = set()
    not_visited = set(mapping.keys())
    combined_cycleseas = CycleSeas()
    while not_visited:
        these_visited = set()
        node_id = not_visited.pop()
        cycleseas = CycleSeas()
        find_cycleseas([node_id], mapping, visited=these_visited, stopping_nodes=visited,
                       cycleseas=cycleseas)
        visited |= these_visited
        # We shouldn't have any partial cycles because we passed an empty visited set.
        combined_cycleseas.add_cycleseas(cycleseas)
        not_visited -= these_visited
    new_mapping = {}
    for node_id, dest_ids in mapping.items():
        new_node_id = combined_cycleseas.node_to_cyclesea.get(node_id, node_id)
        new_dest_ids = set([combined_cycleseas.node_to_cyclesea.get(dest_id, dest_id)
                            for dest_id in dest_ids])
        if new_node_id in new_dest_ids:
            new_dest_ids.remove(new_node_id)
        if new_node_id not in new_mapping:
            new_mapping[new_node_id] = set()
        new_mapping[new_node_id] |= new_dest_ids
    return new_mapping, combined_cycleseas.node_to_cyclesea
