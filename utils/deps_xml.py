#!/usr/bin/env python3
"""
Generate a Makefile .d fragment for the XML includes.
"""

import argparse
import os
import re
import sys

from io import StringIO

from lib.deps import deps_all
from lib.deps import deps_file
from lib.deps import gen_make
from lib.deps import write_deps


parser = argparse.ArgumentParser()
parser.add_argument(
    "inputfile",
    type=argparse.FileType('r'),
    help="""\
Input XML file
""")


my_path = os.path.abspath(__file__)
my_dir = os.path.dirname(my_path)
topdir = os.path.abspath(os.path.join(my_dir, ".."))


xi_include = re.compile('<xi:include[^>]*href="([^"]*)"', re.IGNORECASE)


def main(argv):
    args = parser.parse_args(argv[1:])

    data = StringIO()
    for line in args.inputfile:
        line = line.strip()
        if 'xi:include' not in line:
            continue

        for includefile_path in xi_include.findall(line):
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
