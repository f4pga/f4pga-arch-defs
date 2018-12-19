#! /usr/bin/env python3
""" Tool generate convert a synth_tiles.json (describing an ROI) to a pin map CSV usable for pin placement. """
from __future__ import print_function
import argparse
import json
import sys
import csv


def main():
    parser = argparse.ArgumentParser(description='Converts a synth_tiles.json into a pin map CSV.')
    parser.add_argument(
            "--synth_tiles",
            type=argparse.FileType('r'), required=True,
            help='Pin map synth_tiles JSON file')
    parser.add_argument(
            "--output",
            type=argparse.FileType('w'),
            default=sys.stdout,
            help='The output pin map CSV file')

    args = parser.parse_args()

    synth_tiles = json.load(args.synth_tiles)

    fieldnames = ['name', 'x', 'y', 'z', 'is_clock', 'is_input', 'is_output']
    writer = csv.DictWriter(args.output, fieldnames=fieldnames)

    pads = set()
    writer.writeheader()
    for synth_tile in synth_tiles['tiles'].values():
        if len(synth_tile['pins']) == 0:
            continue

        # TODO: Handle what happens when multiple IO's are at the same x,
        # y location?
        assert len(synth_tile['pins']) == 1
        for pin in synth_tile['pins']:
            assert pin['pad'] not in pads
            pads.add(pin['pad'])
            x = synth_tile['loc']['grid_x']
            y = synth_tile['loc']['grid_y']
            writer.writerow(dict(
                    name=pin['pad'],
                    x=x,
                    y=y,
                    z=0,
                    is_clock=1 if pin['is_clock'] else 0,
                    is_input=0 if pin['port_type'] == 'input' else 1,
                    is_output=0 if pin['port_type'] == 'output' else 1,
            ))

if __name__ == '__main__':
    main()
