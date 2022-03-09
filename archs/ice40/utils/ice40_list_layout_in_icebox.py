#!/usr/bin/env python3

# Python libs
import os.path
import sys

import icebox

# FIXME: Move this into icebox
parts = [
    # LP Series (Low Power)
    "lp384",
    "lp1k",
    "lp8k",
    # Unsupported: "lp640", "lp4k" (alias for lp8k),

    # LM Series (Low Power, Embedded IP)
    # Unsupported: "lm1k", "lm2k",
    "lm4k",

    # HX Series (High Performance)
    "hx1k",
    "hx8k",
    # Unsupported: "hx4k" (alias for hx8k)

    # iCE40 UltraLite
    # Unsupported: "ul640", "ul1k",

    # iCE40 Ultra
    # Unsupported: "ice5lp1k", "ice5lp2k", "ice5lp4k",

    # iCE40 UltraPLus
    # Unsupported: "up3k",
    "up5k",
]


def versions(part):
    return [p for p in parts if p.endswith(part)]


if __name__ == "__main__":
    for name, pins in icebox.pinloc_db.items():
        part, package = name.split('-')
        if ':' in package:
            continue
        for v in versions(part):
            device = "{}.{}".format(v, package)
            print(device)
