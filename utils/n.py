#! /usr/bin/env python3

import os
import pprint
import re
import sys

from lib.asserts import assert_eq

TEMPLATE_PREFIX = "ntemplate."

def mreplace(s, replacements):
    # use these three lines to do the replacement
    rep = dict((re.escape(k), v) for k, v in replacements.items())
    pattern = re.compile("|".join(rep.keys()))
    return pattern.sub(lambda m: rep[re.escape(m.group(0))], s)


def main(args):
    inpath = args[0]
    infile = os.path.basename(inpath)
    indir = os.path.dirname(inpath)
    assert infile.startswith(TEMPLATE_PREFIX), infile
    infile_bit = infile[len(TEMPLATE_PREFIX):]

    outpath = args[1]
    outfile = os.path.basename(outpath)
    outdir = os.path.dirname(outpath)
    assert len(infile_bit) == len(outfile)

    assert_eq(indir, outdir)

    replacement = None
    current_from, current_to = "", ""
    for i, o in zip(infile_bit, outfile):
        if i != 'N':
            assert_eq(i, o)
            continue

        if replacement is None:
            replacement = o

        assert_eq(replacement, o)

    template = open(inpath, "r").read()
    open(outpath, "w").write(template.format(N=replacement.upper()))
    print("Generated {} from {}".format(os.path.relpath(outpath), infile))


if __name__ == "__main__":
    import sys
    main(sys.argv[1:])
