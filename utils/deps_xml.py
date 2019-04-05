#!/usr/bin/env python3
"""
Generate a Makefile .d fragment for the XML includes.
"""

import argparse
import os
import sys

import xml.etree.ElementTree as ET

parser = argparse.ArgumentParser()
parser.add_argument(
    "inputfile", type=argparse.FileType('r'), help="Input XML file"
)


def read_dependencies(inputfile):
    inputpath = os.path.abspath(inputfile.name)
    inputdir = os.path.dirname(inputpath)
    tree = ET.parse(inputfile)
    for el in tree.iter():
        if str(el.tag).endswith('XInclude}include'):
            yield os.path.abspath(os.path.join(inputdir, el.get('href')))


def main(argv):
    args = parser.parse_args(argv[1:])

    for dep in read_dependencies(args.inputfile):
        print(dep)


if __name__ == "__main__":
    sys.exit(main(sys.argv))
