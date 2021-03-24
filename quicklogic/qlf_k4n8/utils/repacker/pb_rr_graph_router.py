#!/usr/bin/env python3
"""
This file implements a simple graph router used for complex block routing
graphs.
"""

from pb_rr_graph import Graph, NodeType

# =============================================================================


class Net:
    """
    This class represents a net for the router. It holds the driver (source)
    node as well as all sink node ids.
    """

    def __init__(self, name):
        self.name = name

        self.source = None
        self.sinks = set()

        self.is_routed = False

    def __str__(self):
        return "{}, fanout={}, {}".format(
            self.name,
            len(self.sinks),
            "routed" if self.is_routed else "unrouted"
        )

# =============================================================================


class Router:
    """
    Simple graph router.

    Currently the routed does a greedy depth-first routing. Each time a path
    from a sink to a source is found it gets immediately annotated with nets.
    """

    def __init__(self, graph):
        self.graph = graph
        self.nets = {}

        # Discover nets from the graph
        self.discover_nets()

    def discover_nets(self):
        """
        Scans the graph looking for nets
        """

        # TODO: For now look for nets only assuming that all of them are
        # unrouted.
        sources = {}
        sinks = {}

        for node in self.graph.nodes.values():

            if node.type not in [NodeType.SOURCE, NodeType.SINK]:
                continue

            # No net
            if node.net is None:
                continue

            # Got a source
            if node.type == NodeType.SOURCE:
                assert node.net not in sources, node.net
                sources[node.net] = node.id

            # Got a sink
            elif node.type == NodeType.SINK:
                if node.net not in sinks:
                    sinks[node.net] = set()
                sinks[node.net].add(node.id)

        # Make nets
        nets = set(sinks.keys()) | set(sources.keys())
        for net_name in nets:

            net = Net(net_name)

            # A net may or may not have a source node. If there is no source
            # then one will be created during routing when a route reaches a
            # node of the top-level CLB.
            if net_name in sources:
                net.source = sources[net_name]

            # A net may or may not have at leas one sink node. If there are
            # no sinks then no routing will be done.
            if net_name in sinks:
                net.sinks = sinks[net_name]

            self.nets[net_name] = net

        # DEBUG
        print("  ", "Nets:")
        keys = sorted(list(self.nets.keys()))
        for key in keys:
            print("   ", str(self.nets[key]))


    def route_net(self, net, debug=False):
        """
        Routes a single net.
        """

        top_level_sources = set()

        def walk_depth_first(node, curr_route=None):

            # FIXME: Two possible places for optimization:
            # - create an edge lookup list indexed by dst node ids
            # - do not copy the current route list for each recursion level

            # Track the route
            if not curr_route:
                curr_route = []
            curr_route.append(node.id)

            # We've hit a node of the same net. Finish.
            if node.type in [NodeType.SOURCE, NodeType.PORT]:
                if node.net == net.name:
                    return curr_route

            # The node is aleady occupied by a different net
            if node.net is not None:
                if node.net != net.name:
                    return None

            # This node is a free source node. If it is a top-level source then
            # store it.
            if node.type == NodeType.SOURCE and node.net is None:
                if node.path.count(".") == 1:
                    top_level_sources.add(node.id)

            # Check all incoming edges
            for edge in self.graph.edges:
                if edge.dst_id == node.id:

                    # Recurse
                    next_node = self.graph.nodes[edge.src_id]
                    route = walk_depth_first(next_node, list(curr_route))

                    # We have a route, terminate
                    if route:
                        return route

            return None

        # Search for a route
        print("  ", net.name)

        # This net has no sinks. Remove annotation from the source node
        if not net.sinks:
            node = self.graph.nodes[net.source]
            node.net = None

        # Route all sinks to the source
        for sink in net.sinks:

            # Find the route
            node = self.graph.nodes[sink]

            top_level_sources = set()
            route = walk_depth_first(node)

            # No route found. Check if we have some free top-level ports that
            # we can use.
            if not route and top_level_sources:

                # Use the frist one
                top_node_id = next(iter(top_level_sources))
                top_node = self.graph.nodes[top_node_id]
                top_node.net = net.name

                # Retry
                route = walk_depth_first(node)

            # No route found
            if not route:
                print("   ", "No route found!")

                # DEBUG
                if debug:
                    with open("unrouted.dot", "w") as fp:
                        fp.write(self.graph.dump_dot(
                            color_by="net",
                            highlight_nodes=set([
                                net.source,
                                sink
                            ])
                        ))

                # Raise an exception
                raise RuntimeError("Unroutable net '{}' from {} to {}".format(
                    net.name,
                    self.graph.nodes[net.source],
                    self.graph.nodes[sink]
                ))

            # Annotate all nodes of the route
            for node_id in route:
                self.graph.nodes[node_id].net = net.name

        # Success
        net.is_routed = True


    def route_nets(self, nets=None, debug=False):
        """
        Routes net with specified names or all nets if no names are given.
        """
        
        # Use all if explicit list not provided
        if nets is None:
            nets = sorted(list(self.nets.keys()))

        # Route nets
        for net_name in nets:
            res = self.route_net(self.nets[net_name], debug=debug)
