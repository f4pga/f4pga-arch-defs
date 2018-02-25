#! /usr/bin/env python3

import sys

def main(args):
    w = args[0]
    outfile = args[1]
    filetype, name, fileext = outfile.split('.')

    template = open("{}.{}".format(filetype, fileext), "r").read()
    open(outfile, "w").write(template.format(W=w[0]))


if __name__ == "__main__":
    import sys
    main(sys.argv[1:])
