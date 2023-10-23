#!/usr/bin/env python3
""" Tool for sanity checking rrgraph CHAN PTC's.
"""
import lxml.etree as ET
import argparse


def check_ptc(xml):
    """ Checks ptc values used on CHANX and CHANY rr graph nodes are valid.

    CHAN ptc numbers are an index per x/y coordinate and channel type (CHANX or
    CHANY).  ptc's at a particular coordinate/type must start at 0, and fill
    to the max value.

    """
    chan_ptcs = {}
    nodes = {}

    for node in xml.find('rr_nodes').iter('node'):
        assert node.attrib['id'] not in nodes
        nodes[node.attrib['id']] = node

        node_type = node.attrib['type']

        if node_type in ['CHANX', 'CHANY']:
            loc_xml = node.find('loc')
            assert loc_xml is not None

            for x in range(int(loc_xml.attrib['xlow']),
                           int(loc_xml.attrib['xhigh']) + 1):
                for y in range(int(loc_xml.attrib['ylow']),
                               int(loc_xml.attrib['yhigh']) + 1):
                    key = (node_type, x, y)

                    if key not in chan_ptcs:
                        chan_ptcs[key] = []

                    chan_ptcs[key].append(
                        (node.attrib['id'], int(loc_xml.attrib['ptc']))
                    )

    for (node_type, x, y), node_ptcs in chan_ptcs.items():
        nodes, ptcs = zip(*node_ptcs)
        starts_at_zero = min(ptcs) == 0
        ends_at_max_val = max(ptcs) == len(ptcs) - 1
        all_values_present = len(ptcs) == len(set(ptcs))

        if not all((starts_at_zero, ends_at_max_val, all_values_present)):
            sorted_nodes = sorted(zip(ptcs, nodes), key=lambda x: x[0])
            for idx, (ptc, node) in enumerate(sorted_nodes):
                if idx == ptc:
                    continue

                if idx > 1:
                    raise ValueError(
                        """\
Gap in ptc value for type = {node_type} @ ({x}, {y})
Expect PTC = {idx}, found {ptc}
Current node is id = {cur_node}
Previous node is id = {prev_node}""".format(
                            x=x,
                            y=y,
                            node_type=node_type,
                            idx=idx,
                            ptc=ptc,
                            cur_node=node,
                            prev_node=sorted_nodes[idx - 1][1],
                        )
                    )
                else:
                    raise ValueError(
                        "Lowest ptc is {ptc} for type = {node_type} @ ({x}, {y})"
                        .format(
                            x=x,
                            y=y,
                            node_type=node_type,
                            ptc=ptc,
                        )
                    )


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('input_xml')

    args = parser.parse_args()

    xml = ET.parse(args.input_xml, ET.XMLParser(remove_blank_text=True))
    check_ptc(xml)


if __name__ == "__main__":
    main()
