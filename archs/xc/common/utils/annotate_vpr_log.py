"""

"""
import argparse
import functools
import pickle
import re
import sqlite3
import sys


def create_lookup_inode(conn, inode_to_graph_map):
    cur = conn.cursor()

    @functools.lru_cache(maxsize=1024 * 1024)
    def lookup_inode(inode):
        if inode not in inode_to_graph_map:
            return '{}'.format(inode)
        else:
            cur.execute(
                """
SELECT phy_tile.name, wire_in_tile.name
FROM graph_node
INNER JOIN wire ON graph_node.node_pkey = wire.node_pkey
INNER JOIN wire_in_tile ON wire.wire_in_tile_pkey = wire_in_tile.pkey
INNER JOIN phy_tile ON wire.phy_tile_pkey = phy_tile.pkey
WHERE graph_node.pkey = ?
LIMIT 1;""", (inode_to_graph_map[inode], )
            )
            tile, wire = cur.fetchone()

            return '{}/{} ({})'.format(tile, wire, inode)

    return lookup_inode


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--rrgraph_node_map', required=True)
    parser.add_argument('--connection_database', required=True)

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

    lookup_inode = create_lookup_inode(conn, inode_to_graph_map)

    def replace_inode(match):
        return match.group(1) + ' ' + lookup_inode(int(match.group(2)))

    NODE_RE = re.compile('(node|rt_node:) ([1-9][0-9]*)')
    for line in sys.stdin:
        sys.stdout.write(NODE_RE.sub(replace_inode, line))


if __name__ == "__main__":
    main()
