#!/usr/bin/env python3
import argparse
import pickle

import lxml.etree as ET

import lib.rr_graph.graph2 as rr
import lib.rr_graph_xml.graph2 as rr_xml

from data_structs import *

# =============================================================================


# =============================================================================


def main():
    
    # Parse arguments
    parser = argparse.ArgumentParser(description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter)

    parser.add_argument(
        "--vpr-db",
        type=str,
        required=True,
        help="VPR database file"
    )
    parser.add_argument(
        "--rr-graph-in",
        type=str,
        required=True,
        help="Input RR graph XML file"
    )
    parser.add_argument(
        "--rr-graph-out",
        type=str,
        default="rr_graph.xml",
        help="Output RR graph XML file (def. rr_graph.xml)"
    )

    args = parser.parse_args()

    # Load the routing graph, build SOURCE -> OPIN and IPIN -> SINK edges.
    xml_graph = rr_xml.Graph(
        input_file_name  = args.rr_graph_in,
        output_file_name = args.rr_graph_out,
        progressbar      = None
    )

    ####
    channels_obj = rr.Channels(
        chan_width_max = 6,
        x_min = 0,
        x_max = 0,
        y_min = 0,
        y_max = 0,
        x_list = [],
        y_list = []
    )

    ####
    nodes_obj = xml_graph.graph.nodes
    edges_obj = xml_graph.graph.edges
    node_remap = lambda x: x

    # Write the routing graph
    xml_graph.serialize_to_xml(
        channels_obj=channels_obj,
        connection_box_obj=None,
        nodes_obj=nodes_obj,
        edges_obj=edges_obj,
        node_remap=node_remap,
    )

# =============================================================================

if __name__ == "__main__":
    main()
