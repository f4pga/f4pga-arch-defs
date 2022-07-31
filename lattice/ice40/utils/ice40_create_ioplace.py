#!/usr/bin/env python3

from __future__ import print_function
import sys
import os

import pcf
import vpr_io_place

import csv
import argparse

parser = argparse.ArgumentParser(
    description='Convert a PCF file into a VPR io.place file.'
)
parser.add_argument(
    "--pcf",
    '-p',
    "-P",
    type=argparse.FileType('r'),
    required=True,
    help='PCF input file'
)
parser.add_argument(
    "--blif",
    '-b',
    type=argparse.FileType('r'),
    required=True,
    help='BLIF / eBLIF file'
)
parser.add_argument(
    "--map",
    '-m',
    "-M",
    type=argparse.FileType('r'),
    required=True,
    help='Pin map CSV file'
)
parser.add_argument(
    "--net",
    '-n',
    type=argparse.FileType('r'),
    required=True,
    help='VPR Packed netlist file'
)
parser.add_argument(
    "--output",
    '-o',
    "-O",
    type=argparse.FileType('w'),
    default=sys.stdout,
    help='The output io.place file'
)


def main(argv):
    args = parser.parse_args()

    reader = csv.DictReader(args.map)
    pin_map = {}
    for row in reader:
        pin_map[row['name']] = (int(row['x']), int(row['y']), int(row['z']))

    locs = pcf.parse_pcf(args.pcf, pin_map)

    io_place = vpr_io_place.IoPlace()

    io_place.read_io_list_from_eblif(args.blif)
    io_place.load_net_file_ios(args.net)

    for name, (loc, pcf_line) in locs.items():
        if io_place.is_net_packed(name):
            io_place.constrain_net(net_name=name, loc=loc, comment=pcf_line)

    io_place.output_io_place(args.output)


if __name__ == "__main__":
    sys.exit(main(sys.argv))
