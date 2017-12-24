#!/usr/bin/env python3
"""
Generate a Makefile fragment for the xml includes.
"""

import os
import re
import subprocess
import sys

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
        # Regenerate the files in this directory
        assert os.path.join(checking_file, "Makefile.gen")
        subprocess.check_call(["make", "-f", "Makefile.gen"], cwd=checking_file)
    elif os.path.exists(checking_file):
        for line in open(checking_file):
            if 'xi:include' not in line:
                continue

            for dep_file in xi_include.findall(line):
                dep_absfile = os.path.abspath(os.path.join(reldir, dep_file))
                dep_absdir = os.path.dirname(dep_absfile)

                toadd = []

                if os.path.exists(os.path.join(dep_absdir, "Makefile.gen")):
                    toadd.append(dep_absdir)
                toadd.append(dep_absfile)

                for a in toadd:
                    if a not in deps:
                        print("  (Adding)", end=" ")
                        deps.append(a)
                    else:
                        print("(Skipping)", end=" ")
                    print("%s found in %s" % (curpath(a), curpath(checking_file)))
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
            assert os.path.exists(os.path.join(dep, "Makefile.gen"))
            f.write("""\
merged.xml: %(dep)s/.gen.stamp
%(dep)s/.gen.stamp:
\tmake -C %(dep)s -f Makefile.gen .gen.stamp

""" % locals())

        elif os.path.isfile(dep):
            depdir = os.path.dirname(dep)
            if os.path.exists(os.path.join(depdir, "Makefile.gen")):
                stamp = " " + os.path.join(depdir, ".gen.stamp")
            else:
                stemp = ""

            f.write("""\
merged.xml: %(dep)s
%(dep)s:%(stamp)s

""" % locals())

        else:
            raise SystemError("Unable to find dependency %s" % checking_file)
