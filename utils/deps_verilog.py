#!/usr/bin/env python3
"""
Generate a Makefile .d fragment for the Verilog includes.
"""

import argparse
import os
import re
import sys

from io import StringIO

from lib.deps import add_dependency
from lib.deps import write_deps

parser = argparse.ArgumentParser()
parser.add_argument(
    "inputfile", type=argparse.FileType('r'), help="Input Verilog file")
parser.add_argument(
    "--file_per_line",
    action='store_true',
    help="Output dependencies file per line, rather than Make .d format.")

v_include = re.compile(r'`include[ ]*"([^"]*)"|\$readmemb\("(.*)",(.*)\)')


def read_dependencies(inputfile):
    matches = v_include.findall(inputfile.read())
    for includefile in matches:
        yield includefile[0] + includefile[1]


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
          add_dependency(data, inputpath, os.path.abspath(
              os.path.join(inputdir, includefile)))

        write_deps(args.inputfile.name, data)


if __name__ == "__main__":
    sys.exit(main(sys.argv))
