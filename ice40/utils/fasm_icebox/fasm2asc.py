#!/usr/bin/env python3
import sys
import argparse
from fasm_icebox_utils import fasm_to_asc


def main(args):
    parser = argparse.ArgumentParser(
        description="Convert FASM to ice40 asc format for icestorm"
    )
    parser.add_argument("--device", help="Device type (eg 1k, 8k)")
    parser.add_argument(
        "input_fasm", help="Input FASM file", type=argparse.FileType("r")
    )
    parser.add_argument(
        "output_asc",
        help="Output ASC file",
        type=argparse.FileType("w"),
        default=sys.stdout,
    )

    args = parser.parse_args()
    fasm_to_asc(args.input_fasm, args.output_asc, device=args.device)


if __name__ == "__main__":
    main(sys.argv[1:])
