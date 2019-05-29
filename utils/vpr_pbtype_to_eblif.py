#!/usr/bin/env python3
"""
Generate an eblif file targetting a given pb_type.xml file.
Used for testing a leaf pb_type can be placed and routed with Verilog to
Routing.

Primarily used by the vpr_test_pbtype cmake function (which is automatically part
of v2x_test_both cmake function).
"""

import argparse
import os
import os.path
import sys

from typing import List

import lxml.etree as ET

from lib.flatten import flatten
from lib.pb_type import Port, ports, get_blif_model, find_leaf


def blif(
        name: str, clocks: List[Port], inputs: List[Port], outputs: List[Port]
) -> str:
    """Generate an eblif for a subckt with set of input and output ports.

    >>> print(blif('mod', ['A'], ['B'], ['C', 'D']))
    .model top
    .inputs A B
    .outputs C D
    .subckt mod A=A B=B C=C D=D
    .cname mod
    .end
    >>> print(blif('mod', [], [('A', 2)], [('C', 2)]))
    .model top
    .inputs A0 A1
    .outputs C0 C1
    .subckt mod A[0]=A0 A[1]=A1 C[0]=C0 C[1]=C1
    .cname mod
    .end
    """
    inputs = list(flatten(clocks)) + list(flatten(inputs))
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


def lut(
        name: str, clocks: List[Port], inputs: List[Port], outputs: List[Port]
) -> str:
    """Generate am eblif for a lut with set of input and output ports.

    >>> print(lut('mod', [], ['A', 'B'], ['D']))
    .model top
    .inputs A B
    .outputs D
    .names A B D
    .end
    >>> print(lut('mod', [], [('A', 2)], [('D', 1)]))
    .model top
    .inputs A0 A1
    .outputs D
    .names A0 A1 D
    .end
    """
    assert not clocks, "LUTs don't have clocks: {}".format(clocks)
    inputs = list(flatten(inputs))
    outputs = list(flatten(outputs))

    assert len(outputs) == 1

    return """\
.model top
.inputs {inputs}
.outputs {outputs}
.names {iomap}
.end""".format(
        inputs=" ".join(d for s, d in inputs),
        outputs=" ".join(s for d, s in outputs),
        iomap=" ".join("{}".format(d) for s, d in inputs + outputs),
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

SUBCKT = '.subckt '


def main(args):
    args = parser.parse_args(args)

    pbtype_xml = ET.parse(args.pb_type)
    pbtype_xml.xinclude()

    pbtype_leaf = find_leaf(pbtype_xml.getroot())
    assert pbtype_leaf is not None, "Unable to find leaf <pb_type> tag in {}".format(
        args.pb_type
    )
    blif_model = get_blif_model(pbtype_leaf)

    _, clocks, inputs, outputs, carry = ports(pbtype_leaf)

    if blif_model.startswith(SUBCKT):
        name = blif_model[len(SUBCKT):].strip()
        outputf = blif
    elif blif_model == '.names':
        name = 'lut{}'.format(len(inputs))
        outputf = lut
    else:
        raise TypeError("Unknown blif_model {}".format(blif_model))

    iname = os.path.basename(args.pb_type)

    outfile = "{}.test.eblif".format(iname)
    if args.output is not None:
        outfile = args.output
    outfile = os.path.abspath(outfile)

    eblif = outputf(name, clocks, inputs, outputs)
    with open(outfile, "w") as f:
        f.write(eblif)

    return 0


if __name__ == "__main__":
    import doctest
    failure_count, test_count = doctest.testmod()
    assert test_count > 0
    assert failure_count == 0, "Doctests failed!"
    sys.exit(main(sys.argv[1:]))
