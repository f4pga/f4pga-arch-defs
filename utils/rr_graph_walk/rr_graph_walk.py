#!/usr/bin/env python3
"""
This utility script allows to walk through the routing graph from a given
starting node id to a given target node id. If the target node id is not
given then it lists all available routes which start at the starting node.
"""

import sys
import argparse
import gc
from collections import namedtuple
from copy import deepcopy

import lxml.etree as ET
import lxml.objectify as objectify

from progressbar import progressbar

# =============================================================================


class RoutingGraph(object):

    Node = namedtuple("Node", "id type xlow ylow xhigh yhigh")
    WalkContext = namedtuple("WalkContext", "node_id depth")

    def __init__(self, xml_file):

        # Load and parse the XML
        print("Loading XML file...")
        parser = ET.XMLParser(remove_comments=True)
        xml_tree = objectify.parse(xml_file, parser=parser)
        xml_root = xml_tree.getroot()

        self.nodes = {}

        self.edges_from = {}
        self.edges_to = {}

        # Import nodes
        self._import_nodes(xml_root)
        # Import edges
        self._import_edges(xml_root)

        del xml_root
        del xml_tree
        del parser
        gc.collect()

    def _import_nodes(self, xml_root):
        """
        Imports nodes from XML file
        """

        print("Importing nodes...")

        # Find the "rr_nodes" section
        xml_rr_nodes = xml_root.find("rr_nodes")
        assert (xml_rr_nodes is not None)

        # Parse nodes
        for xml_node in progressbar(xml_rr_nodes):
            assert xml_node.tag == "node"

            # Find the "loc" tag
            xml_loc = xml_node.find("loc")

            node = RoutingGraph.Node(
                id=int(xml_node.get("id")),
                type=xml_node.get("type"),
                xlow=int(xml_loc.get("xlow")),
                ylow=int(xml_loc.get("ylow")),
                xhigh=int(xml_loc.get("xhigh")),
                yhigh=int(xml_loc.get("yhigh"))
            )

            self.nodes[node.id] = node

        del xml_rr_nodes
        gc.collect()

    def _import_edges(self, xml_root):
        """
        Imports edges from XML file
        """

        def append_edge(edge_dict, key_node, target_node):
            if key_node not in edge_dict.keys():
                edge_dict[key_node] = [target_node]
            else:
                edge_dict[key_node].append(target_node)

        print("Importing edges...")

        # Find the "rr_edges" section
        xml_rr_edges = xml_root.find("rr_edges")
        assert (xml_rr_edges is not None)

        # Parse edges
        edge_count = 0
        for xml_edge in progressbar(xml_rr_edges):
            assert xml_edge.tag == "edge"

            src_node = int(xml_edge.get("src_node"))
            dst_node = int(xml_edge.get("sink_node"))

            append_edge(self.edges_from, src_node, dst_node)
            append_edge(self.edges_to, dst_node, src_node)

            edge_count += 1

        del xml_rr_edges
        gc.collect()

    def node_to_string(self, node_id):
        """
        Converts node information to string
        """

        node = self.nodes[node_id]

        return "%s:%d [%d,%d,%d,%d]" % (
            node.type, node.id, node.xlow, node.ylow, node.xhigh, node.yhigh
        )

    def verify_route(self, route, walk_direction):
        """
        Checks wheter a given route is valid
        """

        visited_nodes = set()

        # Walk through the route
        for i in range(len(route) - 1):

            # Get nodes
            src_id = route[i]
            dst_id = route[i + 1]

            # Find edge from src to dst
            edge_valid = False

            if walk_direction > 0:
                if src_id in self.edges_from:
                    for dst in self.edges_from[src_id]:
                        if dst == dst_id:
                            edge_valid = True
                            break

            if walk_direction < 0:
                if src_id in self.edges_to:
                    for dst in self.edges_to[src_id]:
                        if dst == dst_id:
                            edge_valid = True
                            break

            # Edge not valid
            if not edge_valid:
                return False

            # We have already been there
            if src_id in visited_nodes:
                return False

            visited_nodes.add(src_id)

        # Check the last node
        if route[-1] in visited_nodes:
            return False

        return True

    def walk(self, start_node_id, route_callback, walk_direction):
        """
        Walk the routing graph
        """

        # Copy all nodes. A node is removed from this set once visited.
        walk_nodes = set([node.id for node in self.nodes.values()])

        # Add the starting node id
        stack = list()
        stack.append(RoutingGraph.WalkContext(start_node_id, 0))

        # Walk the graph
        route = []
        while len(stack) > 0:

            # Get current context
            context = stack.pop()

            # Roll back current route
            if context.depth < len(route):
                route = route[:context.depth]

            # Add current node to the route
            route.append(context.node_id)

            # Add all nodes that can be reached from this one through edges
            is_leaf = True

            # Walking forward
            if walk_direction > 0:
                if context.node_id in self.edges_from.keys():
                    for dst in self.edges_from[context.node_id]:
                        # We haven't visited the target
                        if dst in walk_nodes:
                            stack.append(
                                RoutingGraph.WalkContext(
                                    dst, context.depth + 1
                                )
                            )
                            walk_nodes.remove(dst)
                            is_leaf = False

            # Walking backward
            if walk_direction < 0:
                if context.node_id in self.edges_to.keys():
                    for src in self.edges_to[context.node_id]:
                        # We haven't visited the target
                        if src in walk_nodes:
                            stack.append(
                                RoutingGraph.WalkContext(
                                    src, context.depth + 1
                                )
                            )
                            walk_nodes.remove(src)
                            is_leaf = False

            # We are in a leaf node
            if is_leaf:

                # Check the route
                if not self.verify_route(route, walk_direction):
                    raise RuntimeError("The route was invalid!")

                # Invoke the callback
                res = route_callback(self, route)

                # Stop walk
                if res != True:
                    return


# =============================================================================


def print_route(graph, route):
    """
    Print given route with detailed node informations
    """

    for id in route:
        sys.stdout.write("%s, " % graph.node_to_string(id))
    sys.stdout.write("\n")


def save_route(route, fp):
    """
    Save the route to a file (only node indices)
    """

    for id in route:
        fp.write("%d," % id)

    fp.write("\n")
    fp.flush()


# =============================================================================


def main():

    # Parse arguments
    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter
    )

    parser.add_argument(
        "--rr_graph", type=str, required=True, help="Routing graph XML file"
    )
    parser.add_argument(
        "-s", type=int, required=True, help="Start node id (required)"
    )
    parser.add_argument(
        "-e",
        type=int,
        default=-1,
        help="End node id. If not specified then all reachable"
        "leaf nodes will be reported."
    )
    parser.add_argument(
        "--route",
        type=str,
        default="route.txt",
        help="Output route file. Will contain comma separated"
        " indices of visited nodes. One line per route."
    )
    parser.add_argument(
        "--print",
        action="store_true",
        help="Print routes to stdout as they are discovered"
    )
    parser.add_argument(
        "--chan_too",
        action="store_true",
        help="When specified routes which end on CHANX/CHANY "
        "are saved to the route file too."
    )

    if len(sys.argv) <= 1:
        parser.print_help()
        exit(-1)

    args = parser.parse_args()

    # Load the routing graph
    rr_graph = RoutingGraph(args.rr_graph)

    # Open the route file
    route_file = open(args.route, "w")
    target_reached = False

    # The route callback
    def route_callback(graph, route):

        # Get endpoint
        endpoint = graph.nodes[route[-1]]

        # Check if we hit CHANX/CHANY if we do not want to output them then
        # skip those routes.
        if args.chan_too != True:
            if endpoint.type == "CHANX" or endpoint.type == "CHANY":
                return True

        # If we are looking for a particular target node then do not save/print
        # other routes.
        if args.e >= 0 and endpoint.id != args.e:
            return True

        # Save the route
        save_route(route, route_file)

        # Print the route
        if args.print == True:
            print_route(graph, route)

        # Hit anything
        if args.e < 0:
            main.target_reached = True

        # Hit target, stop
        if args.e == endpoint.id:
            main.target_reached = True
            return False

        return True

    # Determine walk direction
    node = rr_graph.nodes[args.s]

    if node.type == "SOURCE" or node.type == "OPIN":
        walk_direction = +1
        print("Walking forward from %d" % args.s, end="")

    if node.type == "SINK" or node.type == "IPIN":
        walk_direction = -1
        print("Walking backward from %d" % args.s, end="")

    if args.e >= 0:
        print(" to %d..." % args.e)
    else:
        print("...")

    # Start the walk
    rr_graph.walk(args.s, route_callback, walk_direction)

    # Check if we have reached the target
    if not target_reached:
        print("No route to the target node!")
        exit(-1)


# =============================================================================

if __name__ == "__main__":
    main()
