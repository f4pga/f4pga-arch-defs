import argparse
import os.path
import re

LOCALPARAM_RE = re.compile(r'^(\s*)localparam\s+([^\s]+)\s*=\s*\d+\s*;\s*$')
DUMPVARS_RE = re.compile(r'^(\s*)\$dumpfile\([^\)]+\)\s*;\s*$')


def main():
    parser = argparse.ArgumentParser(description="")

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
            m = LOCALPARAM_RE.match(l)
            m2 = DUMPVARS_RE.match(l)
            if m:
                prefix_ws = m.group(1)
                param = m.group(2)

                if param in params:
                    print(
                        '{}localparam {} = {};'.format(
                            prefix_ws, param, params[param]
                        ),
                        file=f_out
                    )
                else:
                    print(l.rstrip(), file=f_out)
            elif m2:
                prefix_ws = m2.group(1)
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
