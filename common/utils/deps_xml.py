#!/usr/bin/env python3
"""
Generate a Makefile .d fragment for the XML includes.
"""

import argparse
import os
import sys

from io import StringIO
import xml.etree.ElementTree as ET

from lib.deps import add_dependency
from lib.deps import write_deps

parser = argparse.ArgumentParser()
parser.add_argument(
    "inputfile", type=argparse.FileType('r'), help="Input XML file"
)
parser.add_argument(
    "--file_per_line",
    action='store_true',
    help="Output dependencies file per line, rather than Make .d format."
)


def read_dependencies(inputfile):
    inputpath = os.path.abspath(inputfile.name)
    inputdir = os.path.dirname(inputpath)

    try:
        tree = ET.parse(inputfile)
    except ET.ParseError:
        sys.stderr.write("XML parse error '{}'\n".format(inputfile))
        raise

    for el in tree.iter():
        if str(el.tag).endswith('XInclude}include'):
            yield os.path.abspath(os.path.join(inputdir, el.get('href')))


def main(argv):
    args = parser.parse_args(argv[1:])

    if args.file_per_line:
        for dep in read_dependencies(args.inputfile):
            print(dep)
    else:
        data = StringIO()
        inputpath = os.path.abspath(args.inputfile.name)
        for includefile in read_dependencies(args.inputfile):
            add_dependency(data, inputpath, includefile)

        write_deps(args.inputfile.name, data)


if __name__ == "__main__":
    sys.exit(main(sys.argv))
