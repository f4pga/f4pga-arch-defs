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
        required=False,
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
            pin_map_entry['real_io_assoc'],
        )

    iostandard_defs = {}

    # Load iostandard constraints. This is a temporary workaround that allows
    # to pass them into fasm2bels. As soon as there is support for XDC this
    # will not be needed anymore.
    # If there is a JSON file with the same name as the PCF file then it is
    # loaded and used as iostandard constraint source NOT for the design but
    # to be used in fasm2bels.
    iostandard_constraints = {}

    if args.pcf:
        fname = args.pcf.name.replace(".pcf", ".json")
        if os.path.isfile(fname):
            with open(fname, "r") as fp:
                iostandard_constraints = json.load(fp)
    net_to_pad = io_place.net_to_pad
    if args.pcf:
        pcf_constraints = parse_simple_pcf(args.pcf)
        net_to_pad |= set(
            (constr.net, constr.pad) for constr in pcf_constraints
        )
    # Check for conflicting pad constraints
    net_to_pad_map = dict()
    for (net, pad) in net_to_pad:
        if net not in net_to_pad_map:
            net_to_pad_map[net] = pad
        elif pad != net_to_pad_map[net]:
            print(
                """ERROR:
Conflicting pad constraints for net {}:\n{}\n{}""".format(
                    net, pad, net_to_pad_map[net]
                ),
                file=sys.stderr
            )
            sys.exit(1)

    # Constrain nets
    for net, pad in net_to_pad:
        if not io_place.is_net(net):
            print(
                """ERROR:
Constrained net {} is not in available netlist:\n{}""".format(
                    net, '\n'.join(io_place.get_nets())
                ),
                file=sys.stderr
            )
            sys.exit(1)

        if pad not in pad_map:
            print(
                """ERROR:
Constrained pad {} is not in available pad map:\n{}""".format(
                    pad, '\n'.join(sorted(pad_map.keys()))
                ),
                file=sys.stderr
            )
            sys.exit(1)

        loc, is_output, iob, real_io_assoc = pad_map[pad]

        io_place.constrain_net(
            net_name=net,
            loc=loc,
            comment="set_property LOC {} [get_ports {{{}}}]".format(pad, net)
        )
        if real_io_assoc == 'True':
            if pad in iostandard_constraints:
                iostandard_defs[iob] = iostandard_constraints[pad]
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
