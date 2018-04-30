#!/usr/bin/env python3
"""
Generate a Makefile .d fragment for the Verilog includes.
"""

import argparse
import os
import sys

from io import StringIO

from lib.asserts import assert_eq
from lib.deps import add_dependency
from lib.deps import write_deps

parser = argparse.ArgumentParser()
parser.add_argument(
    "inputfile", type=argparse.FileType('r'), help="Input Verilog file")


def main(argv):
    args = parser.parse_args(argv[1:])

    inputpath = os.path.abspath(args.inputfile.name)
    inputdir = os.path.dirname(inputpath)

    data = StringIO()
    for line in args.inputfile:
        line = line.strip()
        if not line.startswith("`include"):
            continue
        _, includefile = line.split(" ", 1)
        assert_eq(_, "`include")
        assert_eq(includefile[0], '"')
        assert_eq(includefile[-1], '"')
        includefile = includefile[1:-1]

        includefile_path = os.path.abspath(os.path.join(inputdir, includefile))

        add_dependency(data, inputpath, includefile_path)

    write_deps(args.inputfile.name, data)


if __name__ == "__main__":
    sys.exit(main(sys.argv))
