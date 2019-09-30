#!/usr/bin/env python3
""" Creates graph nodes and edges in connection database.

For ROI configurations, pips that would intefer with the ROI are not emitted,
and connections that lies outside the ROI are ignored.

Rough structure:

Add graph_nodes for all IPIN's and OPIN's in the grid based on pin assignments.

Collect tracks used by the ROI (if in used) to prevent tracks from being used
twice.

Make graph edges based on pips in every tile.

Compute which routing tracks are alive based on whether they have at least one
edge that sinks and one edge that sources the routing node.

Build final channels based on alive tracks and insert dummy CHANX or CHANY to
fill empty spaces.  This is required by VPR to allocate the right data.

"""

import argparse
import datetime
from prjxray_edge_library import (
    create_edges, build_channels, set_track_canonical_loc, annotate_pin_feeds,
    compute_segment_lengths, verify_channels
)

import sqlite3

now = datetime.datetime.now


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        '--db_root', required=True, help='Project X-Ray Database'
    )
    parser.add_argument(
        '--connection_database',
        help='Database of fabric connectivity',
        required=True
    )
    parser.add_argument(
        '--pin_assignments', help='Pin assignments JSON', required=True
    )
    parser.add_argument(
        '--synth_tiles',
        help='If using an ROI, synthetic tile defintion from prjxray-arch-import'
    )

    args = parser.parse_args()

    print("{}: Creating edges".format(datetime.datetime.now()))
    create_edges(args)
    print("{}: Done with edges".format(datetime.datetime.now()))

    print("{}: Build channels".format(datetime.datetime.now()))
    build_channels(args.connection_database)
    print("{}: Channels built".format(datetime.datetime.now()))

    print("{}: Finishing database".format(datetime.datetime.now()))

    with sqlite3.connect(args.connection_database) as conn:
        print('{} Set track canonical loc'.format(now()))
        set_track_canonical_loc(conn)

        print('{} Annotate pin feeds'.format(now()))
        annotate_pin_feeds(conn)

        print('{} Compute segment lengths'.format(now()))
        compute_segment_lengths(conn)

        print(
            '{} Flushing database back to file "{}"'.format(
                now(), args.connection_database
            )
        )

    with sqlite3.connect('file:{}?mode=ro'.format(args.connection_database),
                         uri=True) as conn:
        verify_channels(conn)
        print("{}: Channels verified".format(datetime.datetime.now()))


if __name__ == '__main__':
    main()
