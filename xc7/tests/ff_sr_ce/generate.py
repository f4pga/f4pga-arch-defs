import argparse
import re

LOCALPARAM_RE = re.compile(r'^(\s*)localparam\s+([^\s]+)\s*=\s*\d+\s*;\s*$')


def main():
    parser = argparse.ArgumentParser(description="")

    parser.add_argument('--template', required=True)
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

    with open(args.template) as f:
        for l in f:
            m = LOCALPARAM_RE.match(l)
            if m:
                prefix_ws = m.group(1)
                param = m.group(2)

                if param in params:
                    print(
                        '{}localparam {} = {};'.format(
                            prefix_ws, param, params[param]
                        )
                    )
                else:
                    print(l.rstrip())
            else:
                print(l.rstrip())


if __name__ == "__main__":
    main()
