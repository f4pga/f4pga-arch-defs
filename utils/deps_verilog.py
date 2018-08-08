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
parser.add_argument(
    "--file_per_line", action='store_true', help="Output dependencies file per line, rather than Make .d format.")

def read_dependencies(f):
  for line in f:
      line = line.strip()
      if line.startswith("`include"):
        _, includefile = line.split(" ", 1)
        assert_eq(_, "`include")
        assert_eq(includefile[0], '"')
        assert_eq(includefile[-1], '"')
        yield includefile[1:-1]

      if line.startswith("$readmemb"):
        _, includefile = line.split("(", 1)
        assert_eq(_, "$readmemb")
        includefile, _ = includefile.split(",", 1)
        assert_eq(includefile[0], '"')
        assert_eq(includefile[-1], '"')
        yield includefile[1:-1]


def main(argv):
    args = parser.parse_args(argv[1:])

    if args.file_per_line:
      for dep in read_dependencies(args.inputfile):
        print(dep)
    else:
      data = StringIO()
      inputpath = os.path.abspath(args.inputfile.name)
      inputdir = os.path.dirname(inputpath)
      for includefile in read_dependencies(args.inputfile):
        includefile_path = os.path.abspath(os.path.join(inputdir, includefile))
        add_dependency(data, inputpath, includefile_path)

      write_deps(args.inputfile.name, data)


if __name__ == "__main__":
    sys.exit(main(sys.argv))
