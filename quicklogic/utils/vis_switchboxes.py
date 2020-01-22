#!/usr/bin/env python3
import argparse

import xml.etree.ElementTree as ET

from data_structs import *
from data_import import import_data

# =============================================================================


def switchbox_to_dot(switchbox, stage_types=("STREET", "HIGHWAY")):
    dot = []

    # Add header
    dot.append("digraph {} {{".format(switchbox.type))
    dot.append("  graph [nodesep=\"1\", ranksep=\"10\"];")
    dot.append("  splines = \"false\";")
    dot.append("  rankdir = LR;")
    dot.append("  node [shape=record];")

    # Add nodes
    stages = sorted(switchbox.stages.keys())
    for stage_id in stages:
        stage = switchbox.stages[stage_id]

        if stage.type not in stage_types:
            continue

        for switch in stage.switches:
            inputs  = [p for p in switch.pins if p.direction == PinDirection.INPUT]
            outputs = [p for p in switch.pins if p.direction == PinDirection.OUTPUT]

            inp_l = "|".join(["<i{}> {}. {}".format(p.id, p.id, p.name) for p in inputs])
            out_l = "|".join(["<o{}> {}. {}".format(p.id, p.id, p.name) for p in outputs])
            label = "{{{{{}}}|{{{}}}}}".format(inp_l, out_l)
            name  = "stage{}_switch{}".format(stage_id, switch.id)

            dot.append("  {} [rank=\"{}\", label=\"{}\"];".format(name, stage_id, label))

    # Add edges
    for conn in switchbox.connections:

        if switchbox.stages[conn.src_stage].type not in stage_types:
            continue
        if switchbox.stages[conn.dst_stage].type not in stage_types:
            continue

        src_node = "stage{}_switch{}".format(conn.src_stage, conn.src_switch)
        src_port = "o{}".format(conn.src_pin)
        dst_node = "stage{}_switch{}".format(conn.dst_stage, conn.dst_switch)
        dst_port = "i{}".format(conn.dst_pin)

        dot.append("  {}:{} -> {}:{};".format(
            src_node,
            src_port,
            dst_node,
            dst_port
        ))

    # Footer
    dot.append("}")
    return "\n".join(dot)

# =============================================================================


def main():
    
    # Parse arguments
    parser = argparse.ArgumentParser(description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter)

    parser.add_argument(
        "i",
        type=str,
        help="Quicklogic 'TechFile' file"
    )

    args = parser.parse_args()

    # Read and parse the XML file
    xml_tree = ET.parse(args.i)
    xml_root = xml_tree.getroot()

    # Load data
    data = import_data(xml_root)
    switchboxes, = data

    # Generate DOT files with switchbox visualizations
    for switchbox in switchboxes:
        fname = "sbox_{}.dot".format(switchbox.type)
        with open(fname, "w") as fp:
            fp.write(switchbox_to_dot(switchbox, ("STREET",)))

# =============================================================================

if __name__ == "__main__":
    main()
