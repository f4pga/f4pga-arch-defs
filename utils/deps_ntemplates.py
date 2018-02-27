#!/usr/bin/env python3
"""
Generate a Makefile .d fragment for the ntemplate generation.
"""

import argparse
import os
import sys

from io import StringIO

from lib.argparse_extra import ActionStoreBool
from lib.asserts import assert_eq
from lib.deps import deps_file
from lib.deps import write_deps


parser = argparse.ArgumentParser()
parser.add_argument(
    '--verbose', '--no-verbose',
    action=ActionStoreBool, default=os.environ.get('V', '')==1,
    help="Print lots of information about the generation.")
parser.add_argument(
    "inputfile",
    type=argparse.FileType('r'),
    help="The template file.")


my_path = os.path.abspath(__file__)
my_dir = os.path.dirname(my_path)
topdir = os.path.abspath(os.path.join(my_dir, ".."))


def main(argv):
    args = parser.parse_args(argv[1:])

    template = args.inputfile.name
    template_dir = os.path.dirname(template)
    assert os.path.exists(template), template

    n_values = os.environ.get('NTEMPLATE_VALUES').strip().split()
    data = StringIO()
    for n in n_values:
        filename = os.path.basename(template).replace('N', n).replace('ntemplate.','')
        filepath = os.path.join(template_dir, filename)
        data.write(u"""\

{filepath}: {template}
\tcd {template_dir} && $(UTILS_DIR)/n.py {template} {filepath}

{file_deps}: {template}

""".format(
    filepath=filepath,
    template=template,
    template_dir=template_dir,
    file_deps=deps_file(filepath),
))

    write_deps(template, data)


if __name__ == "__main__":
    sys.exit(main(sys.argv))
