#!/usr/bin/env python3

import csv
import pprint
import os.path


TOP_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))


SHEETS = {
    'Yosys': 0,
    'iCE40': 2076254101,
    'ECP5': 1996872500,
    'XC7': 1006733907,
}


def csv_file(name):
    outfile = '{0}/primitives/ff/{0}.csv'.format(name.lower())
    return os.path.join(TOP_DIR, outfile)


def flipflops(name):
    data = open(csv_file(name), 'r').read()

    flipflops = []
    headers = []
    for i, row in enumerate(csv.reader(data.splitlines(), dialect='excel')):
        if i == 0:
            assert not headers
            current = ''
            for i in range(0, len(row)):
                if row[i]:
                    current = row[i]
                row[i] = current
            headers = row
            continue
        elif i == 1:
            for i in range(0, len(row)):
                v = row[i]
                try:
                    v = v[:v.index(" /")]
                except ValueError:
                    pass
                try:
                    v = v[:v.index(" (")]
                except ValueError:
                    pass
                headers[i] = (headers[i], v)
            pprint.pprint(headers)
            continue

        ff = {}
        for (a, b), v in zip(headers, row):
            if not v:
                continue

            if not b:
                assert a not in ff, "{} (with value {}) found in {}".format(
                    (a, b), v, ff
                )
                ff[a] = v
                continue

            if a not in ff:
                ff[a] = {}
            assert b not in ff[a]
            ff[a][b] = v

        flipflops.append(ff)

    for ff in flipflops:
        check_flipflop(ff)

    return flipflops


def check_flipflop(ff):
    """Check the flipflop has a valid configuration."""
    try:
        # Check the required top level properties exist
        for s in ['Name', 'SyncAsync', 'Signal Names', 'Polarity', 'Type',
                  'Class']:
            assert s in ff, "Missing required '{}' property!".format(s)

        # Check all the named signals also have polarity values.
        for s in ff['Signal Names']:
            if s in ('Data Out', 'Data In'):
                continue
            assert s in ff['Polarity'
                           ], "Signal {} doesn't have a polarity!".format(s)

        # Check if it has a Set or Reset signals it has init values for them
        for s in ['Set', 'Reset']:
            if s not in ff['Signal Names']:
                continue
            assert 'Init Values' in ff, "Missing 'Init Values' but have {} signal!".format(
                s
            )
            assert s in ff[
                'Init Values'
            ], "Signal {} exists but no init value for it!".format(s)

        # Check output signal
        assert 'Data Out' in ff['Signal Names'], "Missing 'Data Out' signal!"

        # Check if it is a SR flip flop or latch, then it has both Set and Reset signals
        if 'SR' in ff['Name']:
            assert 'Set' in ff['Signal Names'
                               ], "SR flip flop but no 'Set' signal!"
            assert 'Reset' in ff['Signal Names'
                                 ], "SR flip flop but no 'Reset' signal!"

            assert ff['Init Values'][
                'Set'] == '1', "With SR flip flop 'Set' init value should be 1"
            assert ff['Init Values'][
                'Reset'
            ] == '0', "With SR flip flop 'Reset' init value should be 0"

        # Check if it is a D flip flop or latch it has a Data In signal
        if ff['Name'].startswith('D'):
            assert 'Data In' in ff['Signal Names'], "Missing 'Data In' signal!"

    except AssertionError as e:
        # Add a pretty printed version of the flip flop to the exception to
        # make it easy to see what is going on.
        e.args = (e.args[0] + '\n\n' + pprint.pformat(ff), *e.args[1:])
        raise
