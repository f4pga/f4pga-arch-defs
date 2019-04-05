#!/usr/bin/env python3
"""
Generate a Makefile .d fragment for the Verilog includes.
"""

import argparse
import os
import re
import sys

parser = argparse.ArgumentParser()
parser.add_argument(
    "inputfile", type=argparse.FileType('r'), help="Input Verilog file"
)

v_include = re.compile(r'`include[ ]*"([^"]*)"|\$readmemb\("(.*)",(.*)\)')


def read_dependencies(inputfile):
    matches = v_include.findall(inputfile.read())
    for includefile in matches:
        yield includefile[0] + includefile[1]


def main(argv):
    args = parser.parse_args(argv[1:])

    for dep in read_dependencies(args.inputfile):
        print(dep)

if __name__ == "__main__":
    sys.exit(main(sys.argv))
