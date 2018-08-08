#! /usr/bin/env python3

import os
import sys

from lib.asserts import assert_eq

TEMPLATE_PREFIX = "ntemplate."


def main(args):
    replacement = args[0]

    templatepath = args[1]
    templatefile = os.path.basename(templatepath)
    assert templatefile.startswith(TEMPLATE_PREFIX), templatefile

    outname_template = templatefile[len(TEMPLATE_PREFIX):]
    outname_value = outname_template.replace('N', replacement)

    outpath = args[2]
    outfile = os.path.basename(outpath)

    assert_eq(outname_value, outfile)

    template = open(templatepath, "r").read()
    open(outpath, "w").write(template.format(N=replacement.upper()))
    print("Generated {} from {}".format(
        os.path.relpath(outpath), templatefile))


if __name__ == "__main__":
    main(sys.argv[1:])
