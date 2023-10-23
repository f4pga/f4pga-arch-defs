#!/usr/bin/env python3
"""
Find all source files in the repo.

Excludes the files in the top level .excludes file.
"""

import argparse
import fnmatch
import os.path
import sys

from lib.argparse_extra import ActionStoreBool

MYFILE = os.path.abspath(__file__)
MYDIR = os.path.dirname(MYFILE)

TOPDIR = os.path.abspath(os.path.join(MYDIR, ".."))

parser = argparse.ArgumentParser(
    description=__doc__, fromfile_prefix_chars='@', prefix_chars='-'
)

parser.add_argument(
    '--verbose',
    '--no-verbose',
    action=ActionStoreBool,
    default=os.environ.get('V', '') == '1',
    help="Print information about files ignored."
)

parser.add_argument(
    '--exclude', nargs="*", default=[], help="Extra exclude patterns to add."
)

parser.add_argument(
    'directory', nargs="*", default=[TOPDIR], help="Directory to list from."
)


def stderr(*args, **kw):
    print(*args, **kw, file=sys.stderr, flush=True)


def normpath(r, f):
    return os.path.normpath(os.path.join(r, f))


def main(argv):
    global stderr

    args = parser.parse_args(argv[1:])

    if not args.verbose:
        stderr = lambda *args, **kw: None  # noqa: E731

    stderr("Top level directory:", TOPDIR)

    exclude_patterns = args.exclude
    with open(os.path.join(TOPDIR, ".excludes"), "r") as exclude_file:
        for line in exclude_file:
            # Strip comments
            if '#' in line:
                line = line[:line.find('#')]

            # Strip whitespace
            line = line.strip()

            # Skip empty lines
            if not line:
                continue

            exclude_patterns.append(line)

    stderr("Exclude patterns:", exclude_patterns)
    stderr("Will search:", args.directory)
    for path in args.directory:
        stderr("Looking in:", path)
        for root, dirs, files in os.walk(path, topdown=True):
            for pattern in exclude_patterns:
                # Filter out the directories we want to ignore
                for d in fnmatch.filter(dirs, pattern):
                    stderr(" -dir", normpath(root, d))
                    dirs.remove(d)

            for d in dirs:
                print(os.path.normpath(os.path.join(root, d)))


if __name__ == "__main__":
    sys.exit(main(sys.argv))
