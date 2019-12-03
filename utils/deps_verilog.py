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
    "inputfile", type=argparse.FileType('r'), help="Input Verilog file"
)
parser.add_argument(
    "--file_per_line",
    action='store_true',
    help="Output dependencies file per line, rather than Make .d format."
)

v_include = re.compile(r'`include[ ]*"([^"]*)"|\$readmem[bh]\("(.*)",(.*)\)')


def read_dependencies(inputfile):
    """Read the dependencies out of a verilog file.

    >>> list(read_dependencies(StringIO('''
    ... `include "a.h"
    ... `include "b.h" /* Cmt
    ... `include "c.h"
    ...    */
    ... `include "d.h" // Cmt
    ... // `include "e.h"
    ...   `include "f.h"
    ... ''')))
    ['a.h', 'b.h', 'd.h', 'f.h']

    """
    data = inputfile.read()
    # Strip out the /* */ comments
    data = re.sub('/\\*.*\\*/', '', data, flags=re.DOTALL)
    # Strip out the // comments
    data = re.sub(r'//[^\n]*', '', data)

    matches = v_include.findall(data)
    for includefile in matches:
        yield includefile[0] + includefile[1]


def main(argv):
    args = parser.parse_args(argv[1:])
    inputpath = os.path.abspath(args.inputfile.name)
    inputdir = os.path.dirname(inputpath)

    if args.file_per_line:
        for dep in read_dependencies(args.inputfile):
            print(os.path.abspath(os.path.join(inputdir, dep)))
    else:
        data = StringIO()
        for includefile in read_dependencies(args.inputfile):
            add_dependency(
                data, inputpath,
                os.path.abspath(os.path.join(inputdir, includefile))
            )

        write_deps(args.inputfile.name, data)


if __name__ == "__main__":
    if len(sys.argv) == 1:
        import doctest
        failure_count, test_count = doctest.testmod()
        assert test_count > 0
        assert failure_count == 0, "Doctests failed!"
    sys.exit(main(sys.argv))
