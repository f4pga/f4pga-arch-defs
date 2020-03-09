""" Transform a verilog `local param` values and updates the dumpfile vcd output name;

See example;

.. highlight:: verilog
    ...
    localparam NUM_FF = 4;
    ...
    $dumpfile("testbench_ff_ce_sr_4_tb.vcd");
    ...

to

.. highlight:: verilog
    :emphasize-lines: 3,5
    ...
    localparam NUM_FF = 7;
    ...
    $dumpfile("testbench_ff_ce_sr_7_tb.vcd");
    ...

Useful for generating a number of test cases based a local parameters.


This is useful for generating multiple verilog outputs from a template.

"""
import argparse
import os.path
import re

# Example:
#   localparam NUM_FF = 4;
# group 1 = "   "
# group 2 = "NUM_FF"
LOCALPARAM_RE = re.compile(r'^(\s*)localparam\s+([^\s]+)\s*=.*$')

# Example:
#  $dumpfile(...);
# group 1 = "  "
DUMPFILE_RE = re.compile(r'^(\s*)\$dumpfile\([^\)]+\)\s*;\s*$')


def main():
    parser = argparse.ArgumentParser(description=__doc__)

    parser.add_argument('--template', required=True)
    parser.add_argument('--output', required=True)
    parser.add_argument(
        '--params',
        required=True,
        help="Comma seperated parameter list to set."
    )

    args = parser.parse_args()

    params_list = args.params.split(',')

    params = {}
    for param in params_list:
        k, v = param.split('=')
        params[k] = v

    with open(args.output, 'w') as f_out, open(args.template) as f:
        for l in f:
            localparam_m = LOCALPARAM_RE.match(l)
            dumpfile_m = DUMPFILE_RE.match(l)
            if localparam_m:
                prefix_ws = localparam_m.group(1)
                param = localparam_m.group(2)

                if param in params:
                    print(
                        '{}localparam {} = {};'.format(
                            prefix_ws, param, params[param]
                        ),
                        file=f_out
                    )
                else:
                    print(l.rstrip(), file=f_out)
            elif dumpfile_m:
                prefix_ws = dumpfile_m.group(1)
                base = os.path.basename(args.output)
                root, _ = os.path.splitext(base)
                print(
                    '{}$dumpfile("testbench_{}.vcd");'.format(prefix_ws, root),
                    file=f_out
                )
            else:
                print(l.rstrip(), file=f_out)


if __name__ == "__main__":
    main()
