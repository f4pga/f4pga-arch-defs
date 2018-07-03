#!/usr/bin/env python3

import sys
import os
MYDIR = os.path.dirname(os.path.abspath(__file__))
sys.path.append(os.path.join(MYDIR, "..", "..", "utils"))

import pcf
import eblif

import csv
import argparse

parser = argparse.ArgumentParser(description='Convert a PCF file into a VPR io.place file.')
parser.add_argument(
         "--pcf", '-p', "-P",
        type=argparse.FileType('r'), required=True,
        help='PCF input file')
parser.add_argument(
        "--blif", '-b',
        type=argparse.FileType('r'), required=True,
        help='BLIF / eBLIF file')
parser.add_argument(
        "--map", '-m', "-M",
        type=argparse.FileType('r'), required=True,
        help='Pin map CSV file')
parser.add_argument(
        "--output", '-o', "-O",
        type=argparse.FileType('w'),
        default=sys.stdout,
        help='The output io.place file')


def main(argv):
    args = parser.parse_args()

    reader = csv.DictReader(args.map)
    pin_map = {}
    for row in reader:
        pin_map[row['name']] = (int(row['x']), int(row['y']), int(row['z']))

    locs = pcf.parse_pcf(args.pcf, pin_map)

    blif = eblif.parse_blif(args.blif)

    nl = len("Block name")
    for name in list(locs.keys()):
        if name in blif['inputs']['args']:
            net_type = 'in'
        elif name in blif['outputs']['args']:
            net_type = 'out'
        else:
            raise SyntaxError("""\
Unable to find net {} in blif {}
Found inputs:  {}
Found outputs: {}
""".format(name, args.blif.name, blif['inputs']['args'], blif['outputs']['args']))

        nname = name
        if net_type == 'out':
            nname = 'out:'+name
            locs[nname] = locs[name]
            del locs[name]

        nl = max(nl, len(nname))

    print("""\
#{name:<{nl}} x   y   z    pcf_line
#{s:-^{nl}} --  --  -    ----""".format(
    name="Block Name", nl=nl, s=""), file=args.output)
    for name, ((x, y, z), pcf_line) in locs.items():
        print("""\
{name:<{nl}} {x: 3} {y: 3} {z: 2}  # {pcf_line}""".format(
    name=name, nl=nl, x=x, y=y, z=z, pcf_line=pcf_line),
            file=args.output)


if __name__ == "__main__":
    sys.exit(main(sys.argv))
