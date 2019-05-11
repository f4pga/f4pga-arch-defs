#!/usr/bin/env python3
"""
Generate an eblif file targetting a given pb_type.xml file.
Used for testing a leaf pb_type can be placed and routed with Verilog to
Routing.

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

from typing import List

import lxml.etree as ET

from lib.flatten import flatten
from lib.pb_type import Port, ports, find_leaf


def blif(name: str, inputs: List[Port], outputs: List[Port]) -> str:
    """Generate a blif for a device with set of input and output ports.

    >>> print(blif('mod', ['A', 'B'], ['C', 'D']))
    .model top
    .inputs A B
    .outputs C D
    .subckt mod A=A B=B C=C D=D
    .cname mod
    .end
    >>> print(blif('mod', [('A', 2)], [('C', 2)]))
    .model top
    .inputs A0 A1
    .outputs C0 C1
    .subckt mod A[0]=A0 A[1]=A1 C[0]=C0 C[1]=C1
    .cname mod
    .end
    """
    inputs = list(flatten(inputs))
    outputs = list(flatten(outputs))

    return """\
.model top
.inputs {inputs}
.outputs {outputs}
.subckt {name} {iomap}
.cname {name}
.end""".format(
        name=name,
        inputs=" ".join(d for s, d in inputs),
        outputs=" ".join(s for d, s in outputs),
        iomap=" ".join("{}={}".format(s, d) for s, d in inputs + outputs),
    )


parser = argparse.ArgumentParser(description=__doc__)

parser.add_argument('--pb_type', '-p', help="""\
pb_type.xml file
""")

parser.add_argument(
    '--output',
    '-o',
    help="""\
Output filename, default '<name>.test.eblif'
"""
)


def main(args):
    args = parser.parse_args(args)

    pbtype_xml = ET.parse(args.pb_type)
    pbtype_xml.xinclude()

    pbtype_leaf = find_leaf(pbtype_xml.getroot())
    assert pbtype_leaf is not None, "Unable to find leaf <pb_type> tag in {}".format(
        args.pb_type
    )

    pbtype_name, clocks, inputs, outputs = ports(pbtype_leaf)
    iname = os.path.basename(args.pb_type)

    outfile = "{}.test.eblif".format(iname)
    if args.output is not None:
        outfile = args.output
    outfile = os.path.abspath(outfile)

    eblif = blif(pbtype_name, inputs, outputs)
    with open(outfile, "w") as f:
        f.write(eblif)

    return 0


if __name__ == "__main__":
    import doctest
    doctest.testmod()
    sys.exit(main(sys.argv[1:]))
