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

import lxml.etree as ET

from progressbar import progressbar

# =============================================================================


class RoutingGraph(object):
    """
    A class which represent the routing graph and allows traversing it.
    """

    Node = namedtuple("Node", "id type xlow ylow xhigh yhigh")
    WalkContext = namedtuple("WalkContext", "node_id depth")

    def __init__(self, xml_file):
        """
        Constructs the graph given a VPR routing graph file

        Args:
            xml_file: Name of the XML file with the graph.
        """

        self.nodes = {}

        self.edges_from = {}
        self.edges_to = {}

        # Load and parse the routing graph
        self._load_and_parse_rr_graph(xml_file)

    def _load_and_parse_rr_graph(self, xml_file):
        """
        Loads the routing graph, extracts nodes and edges from the XML.

        Args:
            xml_file: Name of the XML file with the graph.
        """

        def append_edge(edge_dict, key_node, target_node):
            if key_node not in edge_dict.keys():
                edge_dict[key_node] = [target_node]
            else:
                edge_dict[key_node].append(target_node)

        print("Loading and parsing XML file...")

        # Load and initialize parser
        parser = ET.iterparse(xml_file, events=("start", "end"))
        parser = iter(parser)

        # Parse
        expect_nodes = False
        expect_edges = False

        for event, element in progressbar(parser):

            # Start
            if event == "start":

                # Begin "rr_nodes"
                if element.tag == "rr_nodes":
                    expect_nodes = True
                # Begin "rr_edges"
                if element.tag == "rr_edges":
                    expect_edges = True

            # End
            elif event == "end":

                # End "rr_nodes"
                if element.tag == "rr_nodes":
                    expect_nodes = False
                # End "rr_edges"
                if element.tag == "rr_edges":
                    expect_edges = False

                # Got a complete node element
                if expect_nodes and element.tag == "node":

                    # Find the "loc" tag
                    xml_loc = element.find("loc")

                    # Append the node
                    node = RoutingGraph.Node(
                        id=int(element.get("id")),
                        type=element.get("type"),
                        xlow=int(xml_loc.get("xlow")),
                        ylow=int(xml_loc.get("ylow")),
                        xhigh=int(xml_loc.get("xhigh")),
                        yhigh=int(xml_loc.get("yhigh"))
                    )
                    self.nodes[node.id] = node

                # Got a complete edge element
                if expect_edges and element.tag == "edge":
                    src_node = int(element.get("src_node"))
                    dst_node = int(element.get("sink_node"))

                    # Append edge
                    append_edge(self.edges_from, src_node, dst_node)
                    append_edge(self.edges_to, dst_node, src_node)

                # Clear the element
                if element.tag != "loc":
                    element.clear()

        # Clean up
        del parser
        gc.collect()

        print(
            "{} nodes, {} edges".format(len(self.nodes), len(self.edges_from))
        )

    def node_to_string(self, node_id):
        """
        Converts node information to string

        Args:
            node_id: Numerical identifier of a graph node

        Returns:
            String with a pretty node description
        """

        node = self.nodes[node_id]

        return "%s:%d [%d,%d,%d,%d]" % (
            node.type, node.id, node.xlow, node.ylow, node.xhigh, node.yhigh
        )

    def verify_route(self, route, walk_direction):
        """
        Checks wheter a given route is valid

        Args:
            route: Route as a sequence of node ids
            walk_direction: Direction of the route. When > 0 its along graph
                edges direction, when < 0 its the opposite direction.

        Returns:
            True or False
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
        Walk the routing graph from a given starting node id.

        Args:
            start_node_id: Identifier of the starting node. It should be
                a SOURCE/OPIN or SINK/IPIN.
            walk_direction: Direction of the route. When > 0 its SOURCE to
                SINK, when < 0 it is SINK to SOURCE.
            route_callback: A callback function to be called on every
                route found starting from the start node id and ending on
                a graph leaf. If the function returns False then the walk
                stops, if returns true then the walk continues.
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
                if not res:
                    return


# =============================================================================


def print_route(graph, route):
    """
    Print given route with detailed node informations

    Args:
        graph: A RoutingGraph object
        route: A route as a sequence of node ids
    """

    for id in route:
        sys.stdout.write("%s, " % graph.node_to_string(id))
    sys.stdout.write("\n")


def save_route(route, fp):
    """
    Save the route to a file (only node indices)

    Args:
        route: A route as a sequence of node ids
        fp: Open file object
    """

    for id in route:
        fp.write("%d," % id)

    fp.write("\n")
    fp.flush()


# =============================================================================


def main():
    """
    The main.

    Returns:
        None
    """

    # Parse arguments
    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter
    )

    parser.add_argument(
        "--rr_graph", type=str, required=True, help="Routing graph XML file"
    )
    parser.add_argument(
        "-s",
        "--start_inode",
        type=int,
        required=True,
        help="Start node id (required)"
    )
    parser.add_argument(
        "-e",
        "--end_inode",
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
        nonlocal target_reached

        # Get endpoint
        endpoint = graph.nodes[route[-1]]

        # Check if we hit CHANX/CHANY if we do not want to output them then
        # skip those routes.
        if not args.chan_too:
            if endpoint.type == "CHANX" or endpoint.type == "CHANY":
                return True

        # If we are looking for a particular target node then do not save/print
        # other routes.
        if args.end_inode >= 0 and endpoint.id != args.end_inode:
            return True

        # Save the route
        save_route(route, route_file)

        # Print the route
        if args.print:
            print_route(graph, route)

        # Hit anything
        if args.end_inode < 0:
            target_reached = True

        # Hit target, stop
        if args.end_inode == endpoint.id:
            target_reached = True
            return False

        return True

    # Determine walk direction
    node = rr_graph.nodes[args.start_inode]

    if node.type == "SOURCE" or node.type == "OPIN":
        walk_direction = +1
        print("Walking forward from %d" % args.start_inode, end="")

    if node.type == "SINK" or node.type == "IPIN":
        walk_direction = -1
        print("Walking backward from %d" % args.start_inode, end="")

    if args.end_inode >= 0:
        print(" to %d..." % args.end_inode)
    else:
        print("...")

    # Start the walk
    rr_graph.walk(args.start_inode, route_callback, walk_direction)

    # Check if we have reached the target
    if not target_reached:
        print("No route to the target node!")
        exit(-1)


# =============================================================================

if __name__ == "__main__":
    main()
