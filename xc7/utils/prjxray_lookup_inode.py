""" Convert rrgraph inode back into graph_node_pkey and print some information.

This is useful for examining router behavior.  E.g. what tile is this rr graph
inode from?

"""
import argparse
import pickle
import sqlite3
from lib.rr_graph.graph2 import NodeType


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--rrgraph_node_map', required=True)
    parser.add_argument('--connection_database', required=True)
    parser.add_argument('--inode', type=int, required=True)

    args = parser.parse_args()

    with open(args.rrgraph_node_map, 'rb') as f:
        node_map = pickle.load(f)

    inode_to_graph_map = {}
    for graph_node_pkey, rr_inode in node_map.items():
        assert rr_inode not in inode_to_graph_map
        inode_to_graph_map[rr_inode] = graph_node_pkey

    conn = sqlite3.connect(
        'file:{}?mode=ro'.format(args.connection_database), uri=True
    )

    graph_node_pkey = inode_to_graph_map[args.inode]

    cur = conn.cursor()
    cur2 = conn.cursor()
    cur.execute(
        """
SELECT graph_node_type, track_pkey, node_pkey FROM graph_node WHERE pkey = ?
        """, (graph_node_pkey, )
    )
    result = cur.fetchone()
    assert result is not None, graph_node_pkey
    graph_node_type_int, track_pkey, node_pkey = result

    graph_node_type = NodeType(graph_node_type_int)

    wires = []
    for wire_pkey, wire_in_tile_pkey, phy_tile_pkey in cur.execute("""
SELECT pkey, wire_in_tile_pkey, phy_tile_pkey FROM wire WHERE node_pkey = ?
        """, (node_pkey, )):
        cur2.execute(
            """
SELECT name FROM wire_in_tile WHERE pkey = ?
        """, (wire_in_tile_pkey, )
        )
        wire = cur2.fetchone()[0]

        cur2.execute(
            """
SELECT name FROM phy_tile WHERE pkey = ?
        """, (phy_tile_pkey, )
        )
        tile = cur2.fetchone()[0]

        wires.append((tile, wire, wire_pkey))

    print('rr inode: {}'.format(args.inode))
    print('NodeType: {}'.format(graph_node_type))
    print('graph_node_pkey: {}'.format(graph_node_pkey))
    print('Wires ({}):'.format(len(wires)))
    for tile, wire, wire_pkey in wires:
        print('  {}/{} ({})'.format(tile, wire, wire_pkey))


if __name__ == "__main__":
    main()
