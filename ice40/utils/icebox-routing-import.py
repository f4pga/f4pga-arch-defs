#!/usr/bin/env python3

import argparse
import lxml.etree as ET


# Parse arguments
parser = argparse.ArgumentParser()
parser.add_argument(
        '--read_rr_graph', help='Input rr_graph file')
parser.add_argument(
        '--write_rr_graph', help='Output rr_graph file')

args = parser.parse_args()


# Read in existing file
rr_graph = ET.parse(args.read_rr_graph)


# Write out the final rr_graph
with open(args.write_rr_graph, "wb") as f:
    rr_graph.write(f, pretty_print=True)
