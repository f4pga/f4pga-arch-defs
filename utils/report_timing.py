import argparse
import json
import re

from lib.parse_timing import parse_timing

ASSERT_SPEC = re.compile(
    r"(?P<param>[A-Za-z0-9_-]+)(?P<op>=|<|<=|>=|>)(?P<val>[0-9.-]+)"
)


def main():
    parser = argparse.ArgumentParser(
        description="Converts VPR route.log into timing report data"
    )
    parser.add_argument('route_log')
    parser.add_argument(
        '--assert',
        dest='assert_timing',
        help='Comma seperated parameter name list with expected values'
    )
    parser.add_argument(
        '--no_print',
        action='store_false',
        dest='do_print',
        help='Disables printing of output.'
    )

    args = parser.parse_args()

    timing = parse_timing(args.route_log)

    if args.do_print:
        print(json.dumps(timing, indent=2))

    if args.assert_timing:
        for spec in args.assert_timing.split(","):

            match = ASSERT_SPEC.fullmatch(spec)
            assert match is not None, spec

            param = match.group("param")
            op = match.group("op")
            val = float(match.group("val"))

            expected = timing.get(param, None)
            assert expected is not None, \
                "Expect {} {} {} but none reported!".format(param, op, val)

            msg = "Expect {} {} {}, reported {}".format(
                param, op, val, expected
            )

            if op == "=":
                assert expected == val, msg
            elif op == "<":
                assert expected < val, msg
            elif op == "<=":
                assert expected <= val, msg
            elif op == ">":
                assert expected > val, msg
            elif op == ">=":
                assert expected >= val, msg
            else:
                assert False, op


if __name__ == "__main__":
    main()
