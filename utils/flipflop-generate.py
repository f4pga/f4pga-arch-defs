#!/usr/bin/env python3

import argparse
import csv
import hashlib
import json
import os.path
import pprint
import textwrap
import urllib.request

import flipflop


def parse_args():
    parser = argparse.ArgumentParser(
        description='Generate flip flops and such.'
    )
    parser.add_argument('--sheet', default='Yosys', choices=flipflop.SHEETS.keys())
    args = parser.parse_args()

    return args


def truth_table(ff):
    """Get array containing the truth table for flipflop."""
    return ""


def escape_verilog(s):
    return s.replace('$', '\\$')


def describe(ff):
    """Describe the flip flop in human language."""

    if 'Clock' in ff['Signal Names']:

        with_extras = []
        for s in ff['Signal Names']:
            if s in ('Clock', 'Data Out', 'Data In'):
                continue

            # Latches have a "Gate Enable" not a "Clock Enable"
            if s == 'Clock Enable' and ff['Type'] == 'Latch':
                ename = "gate enable"

            # If you have a 'Reset' but your Init Values is 1, then your reset
            # signal is really a set signal.
            elif s == 'Reset' and ff['Init Values']['Reset'] == '1':
                ename = "set"
            else:
                ename = s.lower()

            with_extras.append(
                "{} polarity {}".format(ff['Polarity'][s].lower(), ename)
            )

        if len(with_extras) == 0:
            extras = ""
        elif len(with_extras) == 1:
            extras = " " + with_extras[0]
        else:
            extras = " {} and {}".format(
                ", ".join(with_extras[:-1]), with_extras[-1]
            )

        return "A {} {} {}-type {}{}.".format(
            ff['Polarity']['Clock'].lower(),
            {
                'Flip-flop': 'edge',
                'Latch': 'enable'
            }[ff['Class']],
            ff['Type'],
            ff['Class'].lower(),
            extras,
        )
    else:
        if ff['Type'] == 'SR':
            return "A set-reset latch with {} polarity SET and {} polarity RESET ".format(
                ff['Polarity']['Set'], ff['Polarity']['Reset']
            )
        elif ff['Name'] == '$_FF_':
            return """\
A D-type flip-flop that is clocked from the implicit global clock. (This cell type is usually only used in netlists for formal verification.)"""
        else:
            assert False, pprint.pformat(ff)


sensitivity_polarity = {
    'Positive': 'posedge',
    'Negative': 'negedge',
}
value_polarity = {
    'Positive': 1,
    'Negative': 0,
}


def verilog(ff):
    """Get string containing verilog code for flipflop."""

    # Generate the ports info
    # --------------------------------------------------------------------
    in_ports = (s for n, s in ff['Signal Names'].items() if n != 'Data Out')
    out_ports = [
        ff['Signal Names']['Data Out'],
    ]

    # Generate the sensitivity part of the `always @(<...>) begin` block
    # --------------------------------------------------------------------

    # Assume Sync flip flops only change on the clock edge
    if ff['SyncAsync'] == 'Sync':
        sensitivity = ['Clock']
    # Async flip flops can change on any of the potential inputs accept data in
    else:
        sensitivity = ['Clock', 'Clock Enable', 'Set', 'Reset']

    ss = []
    for s in sensitivity:
        if s not in ff['Signal Names']:
            continue
        ss.append(
            "{} {}".format(
                sensitivity_polarity[ff['Polarity'][s]], ff['Signal Names'][s]
            )
        )

    # Generate the body of the `always @(<...>) begin` block
    # --------------------------------------------------------------------
    always = []

    # Reset + Set signals, Reset takes priority...
    for s in ['Reset', 'Set']:
        if s in ff['Signal Names']:
            always.append(
                """\
    {} ({} == {})
        Q <= {};
""".format(
                    ['if', 'else if'][len(always) > 0],
                    ff['Signal Names'][s],
                    value_polarity[ff['Polarity'][s]],
                    ff['Init Values'][s],
                )[:-1]
            )

    # Data output
    if 'Data In' in ff['Signal Names']:
        if 'Clock Enable' in ff['Signal Names']:
            assert 'Clock' in ff['Signal Names']
            always.append(
                """\
    {} ({} == {})
        {} <= {};
""".format(
                    ['if', 'else if'][len(always) > 0],
                    ff['Signal Names']['Clock Enable'],
                    value_polarity[ff['Polarity']['Clock Enable']],
                    ff['Signal Names']['Data Out'],
                    ff['Signal Names']['Data In'],
                )[:-1]
            )
        elif len(always) > 0:
            always.append(
                """\
    else
        {} <= {};
""".format(
                    ff['Signal Names']['Data Out'],
                    ff['Signal Names']['Data In'],
                )[:-1]
            )
        else:
            always.append(
                """\
    {} <= {};
""".format(
                    ff['Signal Names']['Data Out'],
                    ff['Signal Names']['Data In'],
                )[:-1]
            )

    v = """\
/**
 * {desc}
 *
 * {truth_table}
 *
 * Auto generated with
 *   {json}
 */
module {name} ({in_ports}, {out_ports});
input {in_ports};
output reg {out_ports};
always @({sensitivity}) begin
{always}
end
endmodule
""".format(
        desc="\n * ".join(textwrap.wrap(describe(ff), width=60)),
        truth_table=truth_table(ff),
        json="\n *   ".join(pprint.pformat(ff, width=60).split('\n')),
        name=escape_verilog(ff['Name']),
        in_ports=", ".join(in_ports),
        out_ports=", ".join(out_ports),
        sensitivity=", ".join(ss),
        always="\n".join(always),
    )

    return v


def main():
    args = parse_args()
    flipflops = flipflop.flipflops(args.sheet)
    for i, ff in sorted(enumerate(flipflops), key=lambda ff: ff[-1]['Name']):
        print(i + 3, "-" * 70)
        print(verilog(ff))


if __name__ == "__main__":
    main()
