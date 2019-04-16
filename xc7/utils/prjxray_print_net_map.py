""" Utility for printing route mapping from VPR route output to xc7 db. """
import argparse
import lib.rr_graph_xml.graph2 as xml_graph2
from lib.rr_graph_xml.utils import read_xml_file
from fasm2bels.net_map import create_net_list
import json
import sqlite3


def main():
    parser = argparse.ArgumentParser(description=__doc__)

    parser.add_argument(
        '--connection_db', required=True, help="xc7 connection database."
    )
    parser.add_argument(
        '--route_file', required=True, help="VPR route output file."
    )
    parser.add_argument(
        '--rr_graph', required=True, help="Real or virt xc7 graph"
    )

    args = parser.parse_args()

    xml_graph = xml_graph2.Graph(
        read_xml_file(args.rr_graph), need_edges=False
    )
    graph = xml_graph.graph

    conn = sqlite3.connect(args.connection_db)

    with open(args.route_file) as f:
        net_list = create_net_list(conn, graph, f)
        print(json.dumps([net._asdict() for net in net_list], indent=2))


if __name__ == "__main__":
    main()
