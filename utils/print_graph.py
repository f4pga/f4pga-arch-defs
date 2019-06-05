#!/usr/bin/env python3

import lib.rr_graph.graph as graph


def print_block_types(g):
    '''Sequentially list block types'''
    bg = g.block_grid

    for type_id, bt in bg.block_types._ids.items():
        print(
            "{:4}  ".format(type_id), "{:40s}".format(bt.to_string()),
            bt.to_string(extra=True)
        )


def print_grid(g):
    '''ASCII diagram displaying XY layout'''
    bg = g.block_grid
    grid = bg.size

    # print('Grid %dw x %dh' % (grid.width, grid.height))
    col_widths = []
    for x in range(0, grid.width):
        col_widths.append(
            max(len(bt.name) for bt in bg.block_types_for(col=x))
        )

    print("    ", end=" ")
    for x in range(0, grid.width):
        print("{: ^{width}d}".format(x, width=col_widths[x]), end="   ")
    print()

    print("   /", end="-")
    for x in range(0, grid.width):
        print("-" * col_widths[x], end="-+-")
    print()

    for y in reversed(range(0, grid.height)):
        print("{: 3d} |".format(y, width=col_widths[0]), end=" ")
        for x, bt in enumerate(bg.block_types_for(row=y)):
            assert x < len(col_widths), (x, bt)
            print(
                "{: ^{width}}".format(bt.name, width=col_widths[x]), end=" | "
            )
        print()


def print_nodes(g, lim=None):
    '''Display source/sink edges on all XML nodes'''

    def node_name(node):
        return graph.RoutingGraphPrinter.node(node, g.block_grid)

    def edge_name(node, flip=False):
        return graph.RoutingGraphPrinter.edge(
            g.routing, node, block_grid=g.block_grid, flip=flip
        )

    routing = g.routing
    print(
        'Nodes: {}, edges {}'.format(
            len(routing._ids_map(graph.RoutingNode)),
            len(routing._ids_map(graph.RoutingEdge))
        )
    )

    nodemap = routing._ids_map(graph.RoutingNode)
    edgemap = routing._ids_map(graph.RoutingEdge)
    node2edges = routing.edges_for_allnodes()
    for i, node_id in enumerate(sorted(node2edges.keys())):
        node = nodemap[node_id]
        print()
        if lim and i >= lim:
            print('...')
            break
        print('{} - {} ({})'.format(i, node_name(node), node_id))
        srcs = []
        snks = []
        for e in node2edges[node_id]:
            edge = edgemap[e]
            src, snk = routing.nodes_for_edge(edge)
            if src == node:
                srcs.append(edge)
            elif snk == node:
                snks.append(edge)
            else:
                print("!?@", edge_name(edge))

        print("  Sources:")
        for e in srcs:
            print("   ", edge_name(e))
        if not srcs:
            print("   ", None)

        print("  Sink:")
        for e in snks:
            print("   ", edge_name(e, flip=True))
        if not snks:
            print("   ", None)


def print_graph(g, lim=0):
    print()
    print_block_types(g)
    print()
    print_grid(g)
    print()
    print_nodes(g, lim=lim)
    print()


def main():
    import argparse

    parser = argparse.ArgumentParser("Print rr_graph.xml file")
    parser.add_argument("--lim", type=int, default=0)
    parser.add_argument("rr_graph")
    args = parser.parse_args()

    g = graph.Graph(args.rr_graph)
    print_graph(g, lim=args.lim)


if __name__ == "__main__":
    main()
