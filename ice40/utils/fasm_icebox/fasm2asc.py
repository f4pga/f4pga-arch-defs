#!/usr/bin/env python3
import sys
from fasm_icebox_utils import fasmToAsc

def main(args):
    # parse args
    fasmToAsc(args[0], args[1])

if __name__ == '__main__':
    main(sys.argv[1:])
