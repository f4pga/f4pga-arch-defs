#!/usr/bin/env python3

"""
Generate an eblif file targetting a given pb_type.xml file.
Used for testing a leaf pb_type can be placed and routed with Verilog to
Routing.
"""

import argparse
import math
import os
import os.path
import subprocess
import sys
import tempfile

import lxml.etree as ET

from lib.flatten import flatten
from lib.pb_type import ports


def blif(name, inputs, outputs):
    """
    >>> print(blif('mod', ['A', 'B'], ['C', 'D']))
    .model top
    .inputs A B
    .outputs C D
    .subckt mod A=A B=B C=C D=D
    .end
    >>> print(blif('mod', [('A', 2)], [('C', 2)]))
    .model top
    .inputs A0 A1
    .outputs C0 C1
    .subckt mod A[0]=A0 A[1]=A1 C[0]=C0 C[1]=C1
    .end
    """
    inputs = list(flatten(inputs))
    outputs = list(flatten(outputs))

    return """\
.model top
.inputs {inputs}
.outputs {outputs}
.subckt {name} {iomap}
.end""".format(
        name=name,
        inputs=" ".join(s for s, d in inputs),
        outputs=" ".join(s for s, d in outputs),
        iomap=" ".join("{}={}".format(d, s) for s, d in inputs + outputs),
    )


parser = argparse.ArgumentParser(description=__doc__)

parser.add_argument('--pb_type', '-p', help="""\
pb_type.xml file
""")

parser.add_argument('--output', '-o', help="""\
Output filename, default '<name>.test.eblif'
""")


def main(args):
    args = parser.parse_args(args)

    clocks, inputs, outputs = ports(args.pb_type)
    iname = os.path.basename(args.pb_type)

    outfile = "{}.test.eblif".format(iname)
    if "o" in args and args.o is not None:
        outfile = args.o
    outfile = os.path.abspath(outfile)

    eblif = blif(top, inputs, outputs)
    with open(outfile, "w") as f:
        f.write(eblif)

    return 0


if __name__ == "__main__":
    import doctest
    doctest.testmod()
    sys.exit(main(sys.argv[1:]))
