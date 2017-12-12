#!/usr/bin/env python3
"""
Generate a Makefile fragment for the xml includes.
"""

import os
import sys
import re

def curpath(path):
    return os.path.relpath(path, os.curdir)

my_path = os.path.abspath(__file__)
my_dir = os.path.dirname(my_path)
topdir = os.path.abspath(os.path.join(my_dir, ".."))

my_args = " ".join(sys.argv)
output_file = os.path.abspath(sys.argv[1])
input_file = os.path.abspath(sys.argv[2])

xi_include = re.compile('<xi:include[^>]*href="([^"]*)"', re.IGNORECASE)

# Calculate the deps by recursive extracting the xi:include declarations.
deps = [input_file]
index = 0
while index < len(deps):
    checking_file = deps[index]
    reldir = os.path.dirname(checking_file)

    if os.path.isdir(checking_file):
        pass
    elif os.path.exists(checking_file):
        for line in open(checking_file):
            if 'xi:include' not in line:
                continue

            for dep_file in xi_include.findall(line):
                dep_absfile = os.path.abspath(os.path.join(reldir, dep_file))
                dep_absdir = os.path.dirname(dep_absfile)

                if os.path.exists(os.path.join(dep_absdir, "Makefile.mux")):
                    toadd = dep_absdir
                else:
                    toadd = dep_absfile

                if toadd not in deps:
                    print("  (Adding)", end=" ")
                    deps.append(toadd)
                else:
                    print("(Skipping)", end=" ")
                print("%s found in %s" % (curpath(toadd), curpath(checking_file)))
    else:
        raise SystemError("Unable to find dependency %s" % checking_file)

    index += 1

# Write out the Makefile
with open(output_file, "w") as f:
    f.write("""\
# Makefile fragment generated with %(my_path)s

%(output_file)s: %(my_path)s
\t%(my_path)s %(my_args)s

""" % locals())

    for dep in deps[1:]:
        if os.path.isdir(dep):
            assert os.path.exists(os.path.join(dep, "Makefile.mux"))
            f.write("""\
merged.xml: %(dep)s
%(dep)s:
\tmake -C %(dep)s -f Makefile.mux

.PHONY: %(dep)s

""" % locals())

        elif os.path.exists(dep):
            f.write("""\
merged.xml: %(dep)s
%(dep)s:

""" % locals())

        else:
            raise SystemError("Unable to find dependency %s" % checking_file)
