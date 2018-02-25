#!/usr/bin/env python3
"""
Generate a Makefile .d fragment for the Verilog includes.
"""

import argparse
import os
import sys

from io import StringIO

from lib.asserts import assert_eq
from lib.deps import deps_all
from lib.deps import deps_file
from lib.deps import gen_make
from lib.deps import write_deps


parser = argparse.ArgumentParser()
parser.add_argument(
    "inputfile",
    type=argparse.FileType('r'),
    help="""\
Input Verilog file
""")


my_path = os.path.abspath(__file__)
my_dir = os.path.dirname(my_path)
topdir = os.path.abspath(os.path.join(my_dir, ".."))


def main(argv):
    args = parser.parse_args(argv[1:])

    data = StringIO()
    for line in args.inputfile:
        line = line.strip()
        if not line.startswith("`include"):
            continue
        _, include_filepath = line.split(" ", 1)
        assert_eq(_, "`include")
        assert_eq(include_filepath[0], '"')
        assert_eq(include_filepath[-1], '"')
        include_filepath = include_filepath[1:-1]

        data.write("""
{inputfile_deps}: {includefile_all}

{includefile_make}
""".format(
    inputfile_deps=deps_file(args.inputfile.name),
    includefile_all=deps_all(includefile_path),
    includefile_make=gen_make(includefile_path),
))

    write_deps(args.inputfile.name, data)


if __name__ == "__main__":
    sys.exit(main(sys.argv))
