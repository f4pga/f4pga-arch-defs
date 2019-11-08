#!/usr/bin/env python3

"""
Creates the header file for the OSERDES test with the correct configuration
of the DATA_WIDTH and DATA_RATE
"""

import os
import argparse


def main():
    parser = argparse.ArgumentParser(description=__doc__)

    parser.add_argument('--input', required=True, help="Input top file to be generated")
    parser.add_argument('--output', required=True, help="Output top file to be generated")
    parser.add_argument('--data_width', required=True, help="Data width of the OSERDES")
    parser.add_argument('--data_rate', required=True, help="Data rate of the OSERDES")

    args = parser.parse_args()

    with open(args.input, "r") as f:
        lines = f.read().splitlines()

    with open(args.output, 'w') as f:
        print('`define DATA_WIDTH_DEFINE {}'.format(args.data_width), file=f)
        print('`define DATA_RATE_DEFINE \"{}\"'.format(args.data_rate), file=f)

        for line in lines:
            print(line, file=f)


if __name__ == "__main__":
    main()
