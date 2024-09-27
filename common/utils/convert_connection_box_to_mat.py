#!/usr/bin/env python3
""" Print connection map lookahead in human readable format. """

import argparse
import capnp
from lib.connection_box_tools import load_connection_box, \
    iterate_connection_box, connection_box_to_numpy
import scipy.io as sio
import lib.rr_graph_xml.graph2

# Remove magic import hook.
capnp.remove_import_hook()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        '--schema_path', help='Path to connection map schema', required=True
    )
    parser.add_argument('--lookahead_map', required=True)
    parser.add_argument('--rrgraph', required=True)
    parser.add_argument('--outmat', required=True)

    args = parser.parse_args()

    with open(args.lookahead_map, 'rb') as f:
        cost_map = load_connection_box(args.schema_path, f)

    mat_data = {
        'segments': {},
        'connection_boxes': {},
    }
    segments = {}
    connection_boxes = {}

    have_segments = False
    have_connection_boxes = False

    for path, element in lib.rr_graph_xml.graph2.iterate_xml(args.rrgraph):
        if path == "rr_graph" and element.tag == "segments":
            have_segments = True

        if path == "rr_graph" and element.tag == "connection_boxes":
            have_connection_boxes = True

        if have_segments and have_connection_boxes:
            break

        if path == "rr_graph/connection_boxes" and element.tag == "connection_box":
            connection_boxes[int(element.attrib['id'])
                             ] = element.attrib['name']
            mat_data['connection_boxes'][element.attrib['name']] = int(
                element.attrib['id']
            )

        if path == "rr_graph/segments" and element.tag == "segment":
            segments[int(element.attrib['id'])] = element.attrib['name']
            mat_data['segments'][element.attrib['name']] = int(
                element.attrib['id']
            )

    for segment, connection_box, offset, m in iterate_connection_box(cost_map):

        segment_str = segments[segment]
        box_str = connection_boxes[connection_box]
        print('Processing {} to {}'.format(segment_str, box_str))

        x, y, delay, congestion, fill = connection_box_to_numpy(offset, m)

        if segment_str not in mat_data:
            mat_data[segment_str] = {}

        if box_str not in mat_data[segment_str]:
            mat_data[segment_str][box_str] = {}

        mat_data[segment_str][box_str]['x'] = x
        mat_data[segment_str][box_str]['y'] = y
        mat_data[segment_str][box_str]['delay'] = delay
        mat_data[segment_str][box_str]['congestion'] = congestion
        mat_data[segment_str][box_str]['fill'] = fill

    sio.savemat(args.outmat, mat_data)


if __name__ == "__main__":
    main()
