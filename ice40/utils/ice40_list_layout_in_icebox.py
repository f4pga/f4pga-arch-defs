#!/usr/bin/env python3

# Python libs
import os.path
import sys

MYDIR = os.path.dirname(__file__)

sys.path.insert(0, os.path.join(MYDIR, "..", "..", "third_party", "icestorm", "icebox"))
import icebox

for name, pins in icebox.pinloc_db.items():
    part, package = name.split('-')
    if ':' in package:
        continue
    print("{}.{}".format(part, package))
