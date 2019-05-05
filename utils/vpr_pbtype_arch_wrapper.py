#!/usr/bin/env python3

import argparse
import math
import os
import os.path
import subprocess
import sys
import tempfile

import lxml.etree as ET

from lib import xmlinc
from lib.flatten import flatten
from lib.pb_type import ports


FILEDIR_PATH = os.path.abspath(os.path.join(os.path.dirname(__file__)))
TEMPLATE_PATH = os.path.abspath(
    os.path.join(FILEDIR_PATH, "template.arch.xml")
)


def grid_new(width, height):
    # Generate an empty grid
    tiles = {}
    for x in range(width):
        for y in range(0, height):
            tiles[(x, y)] = '.'
    return tiles


# ABCDEFGHIJKLMNOPQRSTUVWXYZ
def grid_size(tiles):
    width = max(x for x, _ in tiles.keys()) + 1
    height = max(y for _, y in tiles.keys()) + 1
    return (width, height)


def grid_format(tiles):
    """
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


def grid_insert(tiles, x, values):
    """
    >>> t = grid_new(5, 4)
    >>> grid_insert(t, 1, ['I'])
    >>> print(grid_format(t))
       01234
     0 .....
     1 .I...
     2 .....
     3 .....

    >>> t = grid_new(5, 4)
    >>> grid_insert(t, 1, ['I', 'I'])
    >>> grid_insert(t, 3, ['O'])
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


def grid_generate(inputs, outputs):
    height = max(len(inputs), len(outputs)) + 2
    width = len(['.', 'I', '.', 'T', '.', 'O', '.'])
    tiles = grid_new(width, height)
    grid_insert(tiles, 1, ['I'] * len(inputs))
    grid_insert(tiles, 3, ['T'] * (height - 2))
    grid_insert(tiles, 5, ['O'] * len(outputs))
    return tiles


def arch_xml(outfile, name, clocks, inputs, outputs):
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
            "name": name,
            "width": str(width),
            "height": str(height)
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
            if y != 1:
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
            nloc = ET.SubElement(
                ploc,
                "loc",
                {
                    "side": "left",
                    "xoffset": "0",
                    "yoffset": str(i)
                },
            )
            nloc.text = s

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
            nloc = ET.SubElement(
                ploc,
                "loc",
                {
                    "side": "left",
                    "xoffset": "0",
                    "yoffset": str(i)
                },
            )
            nloc.text = s

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
            nloc = ET.SubElement(
                ploc,
                "loc",
                {
                    "side": "right",
                    "xoffset": "0",
                    "yoffset": str(i)
                },
            )
            nloc.text = d

    return tree


def pretty_xml(xml):
    with tempfile.NamedTemporaryFile(suffix=".xml", mode="wb") as f:
        xml.write(f, pretty_print=False)
        f.flush()
        output = subprocess.check_output(["xmllint", "--pretty", "1", f.name])
    return output.decode('utf-8')


parser = argparse.ArgumentParser()
__doc___ = """\
Generate an arch.xml file which includes pb_type.xml and model.xml files for
testing with Verilog to Routing.
"""

parser.add_argument('--pb_type', '-p', help="""\
pb_type.xml file
""")

parser.add_argument('--output', '-o', help="""\
Output filename, default '<name>.arch.xml'
""")


def main(args):
    args = parser.parse_args(args)

    clocks, inputs, outputs = ports(args.pb_type)
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
