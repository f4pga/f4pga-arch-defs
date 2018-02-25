#!/usr/bin/env python3
"""
Generate a Makefile .d fragment for the XML includes.
"""

import argparse
import os
import re
import sys

from lib.asserts import assert_eq
from lib.path import curpath
from lib.path import normpath
from lib.path import depsfile
from lib.path import makefile

parser = argparse.ArgumentParser()
parser.add_argument(
    "depsfile",
    type=argparse.FileType('r'),
    help="""\
Input XML file
""")

"""
carry4_%xor.model.xml: ntemplate.carry4_Nxor.model.xml
        /usr/local/google/home/tansell/work/catx/vtr/utils/n.py $(TARGET) $(PREREQ_FIRST)

carry4_%xor.pb_type.xml: ntemplate.carry4_Nxor.pb_type.xml
        /usr/local/google/home/tansell/work/catx/vtr/utils/n.py $(TARGET) $(PREREQ_FIRST)

carry4_%xor.sim.v: ntemplate.carry4_Nxor.sim.xml
        /usr/local/google/home/tansell/work/catx/vtr/utils/n.py $(TARGET) $(PREREQ_FIRST)
"""

my_path = os.path.abspath(__file__)
my_dir = os.path.dirname(my_path)
topdir = os.path.abspath(os.path.join(my_dir, ".."))


def main(argv):
    args = parser.parse_args(argv[1:])

    xml_filename = args.xmlfile.name
    deps_filename = depsfile(xml_filename)

    depsf = open(deps_filename, "w")

    for line in args.xmlfile:
        line = line.strip()
        if 'xi:include' not in line:
            continue

        for include_filepath in xi_include.findall(line):
            depsf.write("""\

$(call DEPS,{xml_filename}): {include_filepath}

#{include_filepath}:
#\tmake -C $(dir $@) $(notdir $@)
#
#{include_depsfile}:
#\tmake -C $(dir $@) $(notdir $@)

""".format(
    xml_filename=xml_filename,
    include_filepath=include_filepath,
    include_depsfile=depsfile(include_filepath),
))

    print("Created:", depsf.name)
    depsf.close()


if __name__ == "__main__":
    sys.exit(main(sys.argv))
