#! /usr/bin/env python3

import os
import sys
import argparse
import sdfparse

from lib.asserts import assert_eq

TEMPLATE_PREFIX = "ntemplate."


def main(templatepath, timings, replacement, outpath):

    templatefile = os.path.basename(templatepath)
    assert templatefile.startswith(TEMPLATE_PREFIX), templatefile

    outname_template = templatefile[len(TEMPLATE_PREFIX):]
    outname_value = outname_template.replace('N', replacement)

    outfile = os.path.basename(outpath)

    assert_eq(outname_value, outfile)

    template = open(templatepath, "r").read()
    open(outpath, "w").write(template.format(N=replacement.upper(), **timings))
    print(
        "Generated {} from {}".format(os.path.relpath(outpath), templatefile)
    )


if __name__ == "__main__":

    parser = argparse.ArgumentParser()
    parser.add_argument('--template', type=str, help='Input template file')
    parser.add_argument('--sdf', type=str, help='Timings desription file')
    parser.add_argument('--npattern', type=str, help='N pattern value')
    parser.add_argument('--instance', type=str, action='append',
                        help='Instance indicator')
    parser.add_argument('--bel', type=str, action='append',
                        help='BELs that are instaniated by the template')
    parser.add_argument('--process', type=str, choices=['fast', 'slow'],
                        help='Device producion process [fast, slow]')
    parser.add_argument('--delay', type=str, choices=['min', 'avg', 'max'],
                        help='Delay value to use [min, avg, max]')
    parser.add_argument('out', type=str, help='Output filename')

    args = parser.parse_args()
    timings = dict()
    with open(args.sdf, 'r') as fp:
        timings = sdfparse.parse(fp.read())

    selected_bel_timings = dict()

    # gather all the delays from selected BELs/instances
    for b in args.bel:
        for t in timings['cells'][b]:
            for i in args.instance:
                if i in timings['cells'][b]:
                    for delay in timings['cells'][b][i]:
                        selected_bel_timings[delay] = timings['cells'][b][i] \
                                                             [delay] \
                                                             ['delay_paths'] \
                                                             [args.process] \
                                                             [args.delay]

    print(sorted(selected_bel_timings))

    main(args.template, selected_bel_timings, args.npattern, args.out)
