import argparse
import json
import re

from lib.parse_usage import parse_usage

USAGE_SPEC = re.compile(
    r"(?P<type>[A-Za-z0-9_-]+)(?P<op>=|<|<=|>=|>)(?P<val>[0-9]+)"
)


def main():
    parser = argparse.ArgumentParser(
        description="Converts VPR pack.log into usage numbers."
    )
    parser.add_argument('pack_log')
    parser.add_argument(
        '--assert_usage',
        help='Comma seperate block name list with expected usage stats.'
    )
    parser.add_argument(
        '--no_print_usage',
        action='store_false',
        dest='print_usage',
        help='Disables printing of output.'
    )

    args = parser.parse_args()

    usage = {}

    for block, count in parse_usage(args.pack_log):
        usage[block] = count

    if args.print_usage:
        print(json.dumps(usage, indent=2))

    if args.assert_usage:
        for usage_spec in args.assert_usage.split(","):

            match = USAGE_SPEC.fullmatch(usage_spec)
            assert match is not None, usage_spec

            type = match.group("type")
            op = match.group("op")
            val = int(match.group("val"))

            count = int(usage.get(type, 0))

            msg = "Expect usage of block {} {} {}, found {}".format(
                type, op, val, count
            )

            if op == "=":
                assert count == val, msg
            elif op == "<":
                assert count < val, msg
            elif op == "<=":
                assert count <= val, msg
            elif op == ">":
                assert count > val, msg
            elif op == ">=":
                assert count >= val, msg
            else:
                assert False, op


if __name__ == "__main__":
    main()
