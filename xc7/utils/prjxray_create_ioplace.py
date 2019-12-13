""" Convert a PCF file into a VPR io.place file. """
from __future__ import print_function
import argparse
import csv
import json
import sys
import os
import vpr_io_place
from lib.parse_pcf import parse_simple_pcf


def main():
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
        "--output",
        '-o',
        "-O",
        type=argparse.FileType('w'),
        default=sys.stdout,
        help='The output io.place file'
    )
    parser.add_argument(
        "--iostandard_defs", help='(optional) Output IOSTANDARD def file'
    )
    parser.add_argument(
        "--iostandard",
        default="LVCMOS33",
        help='Default IOSTANDARD to use for pins',
    )
    parser.add_argument(
        "--drive",
        type=int,
        default=12,
        help='Default drive to use for pins',
    )
    parser.add_argument(
        "--net",
        '-n',
        type=argparse.FileType('r'),
        required=True,
        help='top.net file'
    )

    args = parser.parse_args()

    io_place = vpr_io_place.IoPlace()
    io_place.read_io_list_from_eblif(args.blif)
    io_place.load_block_names_from_net_file(args.net)

    # Map of pad names to VPR locations.
    pad_map = {}

    for pin_map_entry in csv.DictReader(args.map):
        pad_map[pin_map_entry['name']] = (
            (
                int(pin_map_entry['x']),
                int(pin_map_entry['y']),
                int(pin_map_entry['z']),
            ),
            pin_map_entry['is_output'],
            pin_map_entry['iob'],
        )

    iostandard_defs = {}

    # Load iostandard constraints. This is a temporary workaround that allows
    # to pass them into fasm2bels. As soon as there is support for XDC this
    # will not be needed anymore.
    # If there is a JSON file with the same name as the PCF file then it is
    # loaded and used as iostandard constraint source NOT for the design but
    # to be used in fasm2bels.
    iostandard_constraints = {}

    fname = args.pcf.name.replace(".pcf", ".json")
    if os.path.isfile(fname):
        with open(fname, "r") as fp:
            iostandard_constraints = json.load(fp)    
    
    # Constrain nets
    for pcf_constraint in parse_simple_pcf(args.pcf):
        if not io_place.is_net(pcf_constraint.net):
            print(
                'PCF constraint "{}" from line {} constraints net {} which is not in available netlist:\n{}'
                .format(
                    pcf_constraint.line_str, pcf_constraint.line_num,
                    pcf_constraint.net, '\n'.join(io_place.get_nets())
                ),
                file=sys.stderr
            )
            sys.exit(1)

        if pcf_constraint.pad not in pad_map:
            print(
                'PCF constraint "{}" from line {} constraints pad {} which is not in available pad map:\n{}'
                .format(
                    pcf_constraint.line_str, pcf_constraint.line_num,
                    pcf_constraint.pad, '\n'.join(sorted(pad_map.keys()))
                ),
                file=sys.stderr
            )
            sys.exit(1)

        loc, is_output, iob = pad_map[pcf_constraint.pad]
        io_place.constrain_net(
            net_name=pcf_constraint.net,
            loc=loc,
            comment=pcf_constraint.line_str
        )

        if pcf_constraint.pad in iostandard_constraints:
            iostandard_defs[iob] = iostandard_constraints[pcf_constraint.pad]
        else:
            if is_output:
                iostandard_defs[iob] = {
                    'DRIVE': args.drive,
                    'IOSTANDARD': args.iostandard,
                }
            else:
                iostandard_defs[iob] = {
                    'IOSTANDARD': args.iostandard,
                }

    io_place.output_io_place(args.output)

    # Write iostandard definitions
    if args.iostandard_defs:
        with open(args.iostandard_defs, 'w') as f:
            json.dump(iostandard_defs, f, indent=2)

if __name__ == '__main__':
    main()
