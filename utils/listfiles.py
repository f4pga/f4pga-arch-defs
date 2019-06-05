#!/usr/bin/env python3
"""
Find all source files in the repo.

Excludes the files in the top level .excludes file.
"""

import argparse
import fnmatch
import logging
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


def normpath(r, f):
    return os.path.normpath(os.path.join(r, f))


def listfiles(directory, exclude_patterns):
    for path in directory:
        logging.debug("Looking in: %s", path)
        for root, dirs, files in os.walk(path, topdown=True):
            for pattern in exclude_patterns:
                # Filter out the directories we want to ignore
                for d in fnmatch.filter(dirs, pattern):
                    logging.debug(" -dir %s", normpath(root, d))
                    dirs.remove(d)

                # Filter out the files
                for f in fnmatch.filter(files, pattern):
                    logging.debug("-file %s", normpath(root, f))
                    files.remove(f)

            for f in files:
                yield os.path.normpath(os.path.join(root, f))


def parse_excludes(exclude_name=os.path.join(TOPDIR, ".excludes")):
    exclude_patterns = []
    with open(exclude_name, "r") as exclude_file:
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

    return exclude_patterns


def main(argv):
    args = parser.parse_args(argv[1:])

    if args.verbose:
        logging.basicConfig(level=logging.DEBUG)

    logging.debug("Top level directory: %s", TOPDIR)

    exclude_patterns = args.exclude + parse_excludes()

    logging.debug("Exclude patterns: %s", exclude_patterns)
    logging.debug("Will search: %s", args.directory)
    for item in listfiles(args.directory, exclude_patterns):
        print(item)


if __name__ == "__main__":
    sys.exit(main(sys.argv))
