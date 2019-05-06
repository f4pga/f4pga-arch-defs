#!/usr/bin/env python3
"""
Tool for generate an arch.xml file which includes pb_type.xml and model.xml
files for testing with Verilog to Routing.

Primarily used by the vpr_test_pbtype cmake function (which is automatically part
of v2x_test_both cmake function).
"""

import argparse
import math
import os
import os.path
import subprocess
import sys
import tempfile

from typing import List, Dict, Sequence, Tuple

import lxml.etree as ET

from lib import xmlinc
from lib.flatten import flatten
from lib.pb_type import ports, Port

FILEDIR_PATH = os.path.abspath(os.path.join(os.path.dirname(__file__)))
TEMPLATE_PATH = os.path.abspath(
    os.path.join(FILEDIR_PATH, "template.arch.xml")
)

XPos = int
YPos = int
GridDict = Dict[Tuple[XPos, YPos], str]


def grid_new(width: int, height: int) -> GridDict:
    """Generate an empty grid dictionary."""
    tiles = {}
    for x in range(width):
        for y in range(0, height):
            tiles[(x, y)] = '.'
    return tiles


# ABCDEFGHIJKLMNOPQRSTUVWXYZ
def grid_size(tiles: GridDict) -> Tuple[XPos, YPos]:
    """Get width and height for a grid dictionary."""
    width = max(x for x, _ in tiles.keys()) + 1
    height = max(y for _, y in tiles.keys()) + 1
    return (width, height)


def grid_format(tiles: GridDict) -> str:
    """Print a nicely formatted string from grid dictionary.

    >>> print(grid_format({
    ...  (0, 0): "A", (1, 0): "B", (2, 0): "C",
    ...  (0, 1): "X", (1, 1): "Y", (2, 1): "Z",
    ... }))
       012
     0 ABC
     1 XYZ

    >>> print(grid_format({
    ...  (0, 0): "A", (1, 0): "B", (2, 0): "C", (3, 0): "D", (4, 0): "E",
    ...  (0, 1): "M", (1, 1): "N", (2, 1): "O", (3, 1): "P", (4, 1): "Q",
    ...  (0, 2): "Z", (1, 2): "Y", (2, 2): "X", (3, 2): "W", (4, 2): "V",
    ... }))
       01234
     0 ABCDE
     1 MNOPQ
     2 ZYXWV
    """
    width, height = grid_size(tiles)

    s = []
    # X header
    s.append("   ")
    assert width < 10, width
    for x in range(0, width):
        s.append(str(x))
    s.append("\n")

    for y in range(0, height):
        # Y header
        s.append("{: 2} ".format(y))

        for x in range(0, width):
            s.append(str(tiles[(x, y)])[0])
        s.append('\n')
    return "".join(s[:-1])


def grid_place_in_column(tiles: GridDict, x: XPos, values: List[str]):
    """Place a list of types centered vertical in a given column.

    Modifies the grid dictionary in place.

    >>> t = grid_new(5, 4)
    >>> grid_place_in_column(t, 1, ['I'])
    >>> print(grid_format(t))
       01234
     0 .....
     1 .I...
     2 .....
     3 .....

    >>> t = grid_new(5, 4)
    >>> grid_place_in_column(t, 1, ['I', 'I'])
    >>> grid_place_in_column(t, 3, ['O'])
    >>> print(grid_format(t))
       01234
     0 .....
     1 .I.O.
     2 .I...
     3 .....

    """
    width, height = grid_size(tiles)

    start = math.floor((height - len(values)) / 2)
    for i in range(0, len(values)):
        tiles[(x, start + i)] = values[i]


def grid_generate(inputs: List[str], outputs: List[str]) -> GridDict:
    """Generate a grid dict to fit a set of inputs and outputs.

    Generates a 5 width grid with following columns;
     Column 0 - One input tile per input pins.
     Column 1 - padding
     Column 2 - A single tile.
     Column 3 - padding
     Column 4 - One output tile per output pins.

    """
    height = max(len(inputs), len(outputs)) + 2
    width = len(['I', '.', 'T', '.', 'O'])
    tiles = grid_new(width, height)
    grid_place_in_column(tiles, 0, ['I'] * len(inputs))
    grid_place_in_column(tiles, 2, ['T'] * (height - 2))
    grid_place_in_column(tiles, 4, ['O'] * len(outputs))
    return tiles


def arch_xml(
        outfile: str, name: str, clocks: List[Port], inputs: List[Port],
        outputs: List[Port]
):
    """Generate an arch.xml file which wraps a pb_type."""

    assert name != "TILE", "name ({}) must not be TILE".format(name)
    assert os.path.exists(TEMPLATE_PATH), TEMPLATE_PATH
    tree = ET.parse(TEMPLATE_PATH)
    root = tree.getroot()

    dirpath = os.path.dirname(outfile)
    print(dirpath)

    finputs = [s for s, d in flatten(clocks + inputs)]
    foutputs = [s for s, d in flatten(outputs)]

    tiles = grid_generate(finputs, foutputs)
    width, height = grid_size(tiles)

    mod = root.find("models")
    xmlinc.include_xml(
        mod,
        os.path.join(dirpath, "{}.model.xml".format(name)),
        outfile,
        xptr="xpointer(models/child::node())",
    )

    layouts = root.find("layout")
    l = ET.SubElement(
        layouts,
        "fixed_layout",
        {
            "name": "device",
            # FIXME: See https://github.com/verilog-to-routing/vtr-verilog-to-routing/issues/277
            #"width":  str(width),
            #"height":  str(height),
            "width":  str(max(width, height)),
            "height":  str(max(width, height)),
        },
    )
    l.append(ET.Comment('\n' + grid_format(tiles) + '\n'))

    for x, y in tiles.keys():
        v = tiles[(x, y)]
        if v == '.':
            continue
        elif v == 'I':
            t = 'IBUF'
        elif v == 'O':
            t = 'OBUF'
        elif v == 'T':
            # FIXME: Is this needed?
            if y > 1:
                continue
            t = 'TILE'
        else:
            raise Exception("Unknown tile type {}".format(v))
        ET.SubElement(
            l, "single", {
                "type": t,
                "priority": "1",
                "x": str(x),
                "y": str(y)
            }
        )

    theight = max(len(finputs), len(foutputs))

    cbl = root.find("complexblocklist")
    tile = ET.SubElement(
        cbl,
        "pb_type",
        {
            "name": "TILE",
            "width": "1",
            "height": str(theight)
        },
    )
    xmlinc.include_xml(
        tile,
        os.path.join(dirpath, "{}.pb_type.xml".format(name)),
        outfile,
    )
    ploc = ET.SubElement(
        tile,
        "pinlocations",
        {"pattern": "custom"},
    )
    connect = ET.SubElement(
        tile,
        "interconnect",
    )

    ilocs = []
    olocs = []
    for i in range(0, theight):
        ilocs.append(
            ET.SubElement(
                ploc,
                "loc",
                {
                    "side": "left",
                    "xoffset": "0",
                    "yoffset": str(i)
                },
            )
        )
        ilocs[i].text = ""
        olocs.append(
            ET.SubElement(
                ploc,
                "loc",
                {
                    "side": "right",
                    "xoffset": "0",
                    "yoffset": str(i)
                },
            )
        )
        olocs[i].text = ""

    # Clock pins
    for s, d in flatten(clocks):
        input_tag = ET.SubElement(
            tile,
            "clock",
            {
                "name": s,
                "num_pins": "1",
                "equivalent": "none"
            },
        )
        ET.SubElement(
            connect,
            "direct",
            {
                "input": "TILE.{}".format(s),
                "name": "TILE.{}-{}.{}".format(s, name, d),
                "output": "{}.{}".format(name, d),
            },
        )

        for i in range(0, theight):
            ilocs[i].text += "TILE.{} ".format(s)

    # Input Pins
    for s, d in flatten(inputs):
        input_tag = ET.SubElement(
            tile,
            "input",
            {
                "name": s,
                "num_pins": "1",
                "equivalent": "none"
            },
        )
        ET.SubElement(
            connect,
            "direct",
            {
                "input": "TILE.{}".format(s),
                "name": "TILE.{}-{}.{}".format(s, name, d),
                "output": "{}.{}".format(name, d),
            },
        )

        for i in range(0, theight):
            ilocs[i].text += "TILE.{} ".format(s)

    # Output Pins
    for d, s in flatten(outputs):
        output_tag = ET.SubElement(
            tile,
            "output",
            {
                "name": d,
                "num_pins": "1",
                "equivalent": "none"
            },
        )
        ET.SubElement(
            connect,
            "direct",
            {
                "input": "{}.{}".format(name, s),
                "name": "TILE.{}-{}.{}".format(s, name, d),
                "output": "TILE.{}".format(d),
            },
        )
        for i in range(0, theight):
            olocs[i].text += "TILE.{} ".format(d)

    return tree


def pretty_xml(xml):
    """Use xmllint to prettify the XML output."""
    with tempfile.NamedTemporaryFile(suffix=".xml", mode="wb") as f:
        xml.write(f, pretty_print=False)
        f.flush()
        output = subprocess.check_output(["xmllint", "--pretty", "1", f.name])
    return output.decode('utf-8')


parser = argparse.ArgumentParser(description=__doc__)

parser.add_argument('--pb_type', '-p', help="""\
pb_type.xml file
""")

parser.add_argument(
    '--output', '-o', help="""\
Output filename, default '<name>.arch.xml'
"""
)


def main(args):
    args = parser.parse_args(args)

    pbtype_xml = ET.parse(args.pb_type)
    pbtype_name, clocks, inputs, outputs = ports(pbtype_xml.getroot())
    iname = os.path.basename(args.pb_type)

    outfile = "{}.arch.xml".format(iname)
    if args.output is not None:
        outfile = args.output
    outfile = os.path.abspath(outfile)

    xml = arch_xml(outfile, pbtype_name, clocks, inputs, outputs)
    with open(outfile, 'w') as f:
        f.write(pretty_xml(xml))

    return 0


if __name__ == "__main__":
    import doctest
    doctest.testmod()
    sys.exit(main(sys.argv[1:]))
