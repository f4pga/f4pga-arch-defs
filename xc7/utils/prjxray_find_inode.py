""" Find an rr node by specifying a wire name (e.g. INT_R_X3Y149/WL1BEG0).

This is useful for examining router behavior.  E.g. what which inode represents
this wire?

"""
import argparse
import pickle
import sqlite3
from lib.rr_graph.graph2 import NodeType


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--rrgraph_node_map', required=True)
    parser.add_argument('--connection_database', required=True)
    parser.add_argument('--wire', required=True)

    args = parser.parse_args()

    with open(args.rrgraph_node_map, 'rb') as f:
        node_map = pickle.load(f)
    conn = sqlite3.connect(
        'file:{}?mode=ro'.format(args.connection_database), uri=True
    )

    tile, wire = args.wire.split('/')

    cur = conn.cursor()
    cur.execute(
        """
SELECT pkey, node_pkey FROM wire WHERE
    wire_in_tile_pkey IN (SELECT pkey FROM wire_in_tile WHERE name = ?)
AND
    phy_tile_pkey = (SELECT pkey FROM phy_tile WHERE name = ?)
    """, (wire, tile)
    )
    results = cur.fetchall()
    assert len(results) == 1

    wire_pkey, node_pkey = results[0]

    print('Wire ({}): {}'.format(wire_pkey, args.wire))
    for (graph_node_pkey, graph_node_type) in cur.execute("""
SELECT pkey, graph_node_type FROM graph_node WHERE node_pkey = ?
        """, (node_pkey, )):
        print(
            '  Node inode={} pkey={} {}'.format(
                node_map.get(graph_node_pkey), graph_node_pkey,
                NodeType(graph_node_type)
            )
        )


if __name__ == "__main__":
    main()
