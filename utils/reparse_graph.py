import lib.rr_graph.graph as g
import lib.rr_graph.channel as channel
from lib.rr_graph import Position

import sys
import lxml.etree as ET
import os


def main():
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument("rr_graph_in")
    parser.add_argument("rr_graph_out")
    args = parser.parse_args()

    fn = args.rr_graph_in
    fn_out = args.rr_graph_out
    assert fn != fn_out

    print('Loading g')
    g = g.Graph(rr_graph_file=fn)
    print('Converting to XML')
    e = g.to_xml()
    print('Dumping')
    open(fn_out, 'w').write(ET.tostring(e, pretty_print=True).decode('ascii'))

    print('Exiting')


if __name__ == "__main__":
    main()
