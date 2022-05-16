""" Tool for implementing a simple cache

Tool returns 0 if cache is valid, returns non-zero is cache is invalid.

check_cache.py <args> || (<build_cache> && update_cache.py <args>)
"""
import argparse
import hashlib
import pathlib
import os.path
import sys


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('cache_input')
    parser.add_argument('cache_value')
    parser.add_argument('cache_outputs', nargs='+')

    args = parser.parse_args()

    if not os.path.exists(args.cache_input):
        sys.exit(-1)

    if not os.path.exists(args.cache_value):
        sys.exit(-1)

    for out in args.cache_outputs:
        if not os.path.exists(out):
            sys.exit(-1)

    with open(args.cache_input, 'rb') as f:
        m = hashlib.sha1()
        m.update(f.read())
        h = m.hexdigest()

    with open(args.cache_value) as f:
        if f.read().strip() != h:
            sys.exit(-1)

    # Update file timestamps
    pathlib.Path(args.cache_value).touch(exist_ok=True)
    for out in args.cache_outputs:
        pathlib.Path(out).touch(exist_ok=True)


if __name__ == "__main__":
    main()
