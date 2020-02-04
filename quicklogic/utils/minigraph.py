"""
A small utility framework for handling directed graphs
"""
from collections import namedtuple
from collections import defaultdict
import itertools

# =============================================================================

"""
A graph node

id          - Node id.
is_locked   - If True then the node cannot be pruned
metadata    - Arbitrary metadata object.
"""
Node = namedtuple("Node", "id is_locked metadata")

"""
A graph edge

id          - Edge id.
src_node    - Source node id.
dst_node    - Destination node id.
metadata    - List of arbitrary metadata items.
"""
Edge = namedtuple("Edge", "id src_node dst_node metadata")

# =============================================================================


class MiniGraph(object):
    """
    The mini graph.
    """

    def __init__(self):

        # A dict of all nodes indexed by their ids
        self.nodes = {}
        # A dict of all edges indexed by their ids
        self.edges = {}

        # A next ids to be assigned when something is added
        self.next_node_id = 0
        self.next_edge_id = 0


    def add_node(self, metadata=None, is_locked=True):
        """
        Adds a node to the graph. Returns its id.
        """
        node = Node(
            id = self.next_node_id,
            is_locked = is_locked,
            metadata  = metadata,
        )

        self.nodes[node.id] = node
        self.next_node_id += 1
        return node.id

    def remove_node(self, node_id):
        """
        Removes the node from the graph and all edges mentioning it.
        """
        assert node_id in self.nodes, node_id

        # Build a list of edges to remove
        edges_to_prune = set()
        for edge in self.edges.values():
            if edge.src_node == node_id or edge.dst_node == node_id:
                edges_to_prune.add(edge.id)

        # Remove node
        del self.nodes[node_id]
        # Remove edges
        for edge_id in edges_to_prune:
            del self.edges[edge_id]

    def update_node(self, node_id, metadata=None, is_locked=None):
        """
        Updates a node with the given id.
        """
        old_node = self.nodes[node_id]
        new_node = Node(
            id = old_node.id,
            is_locked = old_node.is_locked if is_locked is None else is_locked,
            metadata = old_node.metadata if metadata is None else metadata,
            )
        self.nodes[node_id] = new_node

    def add_edge(self, src_node, dst_node, metadata=()):
        """
        Adds an edge to the graph. Returns its id.
        """
        assert src_node in self.nodes, src_node
        assert dst_node in self.nodes, dst_node

        edge = Edge(
            id = self.next_edge_id,
            src_node = src_node,
            dst_node = dst_node,
            metadata = list(metadata),
        )

        self.edges[edge.id] = edge
        self.next_edge_id += 1
        return edge.id


    def optimize(self):
        """
        Optimizes the graph by removing nodes that have only one input and/or
        only one output. Preserves nodes makred as locked.
        """

        # Count inputs and outpus of each node
        inp_count = defaultdict(lambda: 0)
        out_count = defaultdict(lambda: 0)

        for edge in self.edges.values():
            inp_count[edge.dst_node] += 1
            out_count[edge.src_node] += 1

        # Identify candidates to prune
        candidates = set()
        for node in self.nodes.values():
            if not node.is_locked:
                if inp_count[node.id] > 0 and out_count[node.id] > 0:
                    if inp_count[node.id] == 1 or out_count[node.id] == 1:
                        candidates.add(node.id)
        
        # Prune one-by-one
        for node in candidates:
            
            # Get all neighbors, identify edges to prune, store their metadata
            src_neighbors  = set()
            src_metadata   = defaultdict(lambda: [])
            dst_neighbors  = set()
            dst_metadata   = defaultdict(lambda: [])
            edges_to_prune = set()    

            for edge in self.edges.values():

                if edge.src_node == node:
                    dst_neighbors.add(edge.dst_node)
                    dst_metadata[edge.dst_node].append(edge.metadata)
                    edges_to_prune.add(edge.id)
 
                if edge.dst_node == node:
                    src_neighbors.add(edge.src_node)
                    src_metadata[edge.src_node].append(edge.metadata)
                    edges_to_prune.add(edge.id)

            # Make new edges. Connect all-to-all as there always be only one
            # source or only one destinagion.
            # Join metadata from collapsed edges.
            for src, dst in itertools.product(src_neighbors, dst_neighbors):
                metadata  = [m for meta in src_metadata[src] for m in meta]
                metadata += [m for meta in dst_metadata[dst] for m in meta]
                self.add_edge(src, dst, metadata)

            # Remove edges and the node
            del self.nodes[node]

            for edge in edges_to_prune:
                del self.edges[edge]

    def prune_leafs(self):
        """
        Removes leaf nodes that are not locked.
        """

        # Count inputs and outpus of each node
        inp_count = defaultdict(lambda: 0)
        out_count = defaultdict(lambda: 0)

        for edge in self.edges.values():
            inp_count[edge.dst_node] += 1
            out_count[edge.src_node] += 1

        # Identify candidates to prune
        candidates = set()
        for node in self.nodes.values():
            if not node.is_locked:
                if inp_count[node.id] == 0 or out_count[node.id] == 0:
                    candidates.add(node.id)

        # Remove nodes
        for node_id in candidates:
            self.remove_node(node_id)

    def dump_dot(self):
        """
        Returns a string with the graph in DOT format suitable for the
        Graphviz.
        """
        dot = []

        # Add header
        dot.append("digraph g {")
        dot.append(" graph [ranksep=\"10\"];")
        dot.append(" rankdir=LR;")
        dot.append(" node [style=filled];")

        # Add nodes
        for node in self.nodes.values():

            label = str(node.id)
            if node.metadata is not None:
                label += "\n'{}'".format(str(node.metadata))

            if node.is_locked:
                color = "#FFFFFF"
            else:
                color = "#808080"

            dot.append(" node_{id} [label=\"{label}\", fillcolor=\"{color}\"];".format(
                id=node.id,
                label=label,
                color=color
            ))

        # Add edges
        for edge in self.edges.values():

            label = str(edge.id)
            if len(edge.metadata):
                label += ":\n" + "\n".join(["'{}'".format(m) for m in edge.metadata])

            dot.append(" node_{} -> node_{} [label=\"{}\"];".format(
                edge.src_node,
                edge.dst_node,
                label
            ))

        # Footer
        dot.append("}")
        return "\n".join(dot)

# =============================================================================


if __name__ == "__main__":

    # TODO: Make some actual tests from the example below

    g = MiniGraph()
    
#    # Define the graph
#    g.add_node()
#    g.add_node(False)
#    g.add_node()
#    g.add_node()
#    g.add_node()
#    g.add_node()
#    g.add_node(False)
#    g.add_node()
#    g.add_node()
#
#    g.add_edge(0, 1)
#
#    g.add_edge(1, 2)
#    g.add_edge(1, 3)
#
#    g.add_edge(2, 4)
#    g.add_edge(2, 5)
#    g.add_edge(3, 4)
#    g.add_edge(3, 5)
#
#    g.add_edge(4, 6)
#    g.add_edge(5, 6)
#
#    g.add_edge(6, 7)
#    g.add_edge(6, 8)

    g.add_node(is_locked=False)
    g.add_node(is_locked=False)
    g.add_node(is_locked=False)
    g.add_node(is_locked=False)
    g.add_node(is_locked=False)
    g.add_node(is_locked=False)

    g.add_edge(0, 2, ["A"])
    g.add_edge(1, 3)
    g.add_edge(2, 4, ["B"])
    g.add_edge(2, 5, ["C"])
    g.add_edge(3, 4)
    g.add_edge(3, 5)


    # Dump
    with open("minigraph1.dot", "w") as fp:
        fp.write(g.dump_dot())

    # Optimize
    g.optimize()

    # Dump
    with open("minigraph2.dot", "w") as fp:
        fp.write(g.dump_dot())

