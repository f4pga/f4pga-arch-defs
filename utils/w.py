#! /usr/bin/env python3

import sys


def main(args):
    for outfile in args:
        if len(outfile) == 1:
            main(['pb_type.{}.xml'.format(outfile), 'sim.{}.v'.format(outfile)])
            continue

        filetype, w, fileext = outfile.split('.')

        template = open("{}.{}".format(filetype, fileext), "r").read()
        open(outfile, "w").write(template.format(W=w[0]))


if __name__ == "__main__":
    import sys
    main(sys.argv[1:])
