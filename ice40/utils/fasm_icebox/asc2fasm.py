#!/usr/bin/env python3
import sys
from fasm_icebox_utils import asc_to_fasm


def main(args):
    # parse args
    with open(args[1], "w") as f:
        asc_to_fasm(args[0], f)


if __name__ == "__main__":
    main(sys.argv[1:])
