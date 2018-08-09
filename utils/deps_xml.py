#!/usr/bin/env python3
"""
Generate a Makefile .d fragment for the XML includes.
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
    "inputfile", type=argparse.FileType('r'), help="Input XML file")
parser.add_argument(
    "--file_per_line", action='store_true', help="Output dependencies file per line, rather than Make .d format.")

xi_include = re.compile('<xi:include[^>]*href="([^"]*)"', re.IGNORECASE)

def read_dependencies(f):
  inputpath = os.path.abspath(f.name)
  inputdir = os.path.dirname(inputpath)
  for line in f:
      line = line.strip()
      if 'xi:include' not in line:
          continue

      for includefile in xi_include.findall(line):
          yield os.path.abspath(
              os.path.join(inputdir, includefile))

def main(argv):
    args = parser.parse_args(argv[1:])

    if args.file_per_line:
      for dep in read_dependencies(args.inputfile):
        print(dep)
    else:
      data = StringIO()
      inputpath = os.path.abspath(args.inputfile.name)
      for dep in read_dependencies(args.inputfile):
        add_dependency(data, inputpath, dep)

      write_deps(args.inputfile.name, data)


if __name__ == "__main__":
    sys.exit(main(sys.argv))
