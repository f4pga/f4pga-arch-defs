#!/usr/bin/env python3
"""
Set a file to the newest modified time of the other files.
"""

import argparse
import os
import sys
import time

from lib import argparse_extra

parser = argparse.ArgumentParser()
parser.add_argument(
    "--outfile",
    "--output",
    "-o",
    type=str,
    help="""\
The file to set the modtime on.
"""
)
parser.add_argument(
    "--verbose",
    action=argparse_extra.ActionStoreBool,
    default=os.environ.get('V', '') == 1,
    help="""\
Files to get the input time from.
"""
)
parser.add_argument(
    "files",
    type=str,
    nargs="+",
    help="""\
Files to get the input time from.
"""
)

my_path = os.path.abspath(__file__)
my_dir = os.path.dirname(my_path)
topdir = os.path.abspath(os.path.join(my_dir, ".."))


def main(argv):
    args = parser.parse_args(argv[1:])

    t = 0
    newest = None
    for filepath in args.files:
        if not os.path.exists(filepath):
            print(
                "Did not find {}, skipping!".format(filepath), file=sys.stderr
            )
            continue
        assert os.path.isfile(filepath), filepath

        mtime = os.path.getmtime(filepath)
        if args.verbose:
            print("{} has modtime of {}".format(filepath, mtime))
        if mtime > t:
            newest = filepath
            t = mtime

    if not newest:
        print("Did not find any files, using current time!", file=sys.stderr)
        t = time.time()

    if not os.path.exists(args.outfile):
        f = open(args.outfile, "w")
        f.close()

    assert os.path.exists(args.outfile), args.outfile
    assert os.path.isfile(args.outfile), args.outfile
    if os.path.getmtime(args.outfile) == t:
        if args.verbose:
            print(
                "modtime of {} already {} (from {})".format(
                    args.outfile, t, newest
                )
            )
            t += 1
    if args.verbose:
        print(
            "Setting modtime of {} to {} (from {})".format(
                args.outfile, t, newest
            )
        )
    os.utime(args.outfile, times=(time.time(), t))


if __name__ == "__main__":
    sys.exit(main(sys.argv))
