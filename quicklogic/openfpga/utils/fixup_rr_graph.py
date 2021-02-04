#!/usr/bin/env python3
"""
This is a skeleton script for processing RR graph generated using an arch.xml
from OpenFPGA project.

Currently the script doesn't do anything to the graph.
"""
import argparse

from shutil import copyfile

# =============================================================================


def main():

    # Parse arguments
    parser = argparse.ArgumentParser()

    parser.add_argument(
        "--rr-graph-in",
        required=True,
        type=str,
        help="Input RR graph XML"
    )
    parser.add_argument(
        "--rr-graph-out",
        required=True,
        type=str,
        help="Output RR graph XML"
    )

    args = parser.parse_args()

    # FIXME: For now just copy the file
    copyfile(args.rr_graph_in, args.rr_graph_out)


if __name__ == "__main__":
    main()
