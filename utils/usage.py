import argparse
import re
import json

USAGE_PATTERN = re.compile(r'^Netlist +([0-9]+)\sblocks of type: (.*)$')

def parse_usage(pack_log):
    with open(pack_log) as f:
        for l in f:
            m = re.match(USAGE_PATTERN, l.strip())
            if m:
                yield (m.group(2), int(m.group(1)))

def main():
    parser = argparse.ArgumentParser(description="Converts pack.log into usage numbers.")
    parser.add_argument('pack_log')
    parser.add_argument('--assert_usage', help='Comma seperate block name list with expected usage stats.')

    args = parser.parse_args()

    usage = {}

    for block, count in parse_usage(args.pack_log):
        usage[block] = count

    if args.assert_usage:
        blocks = dict(b.split('=') for b in args.assert_usage.split(','))

        for block in usage:
            if block in blocks:
                assert usage[block] == int(blocks[block]), 'Expect usage of block {} = {}, found {}'.format(
                        block, int(blocks[block]), usage[block])
            else:
                assert usage[block] == 0, 'Expect usage of block {} = 0, found {}'.format(
                        block. usage[block])

    print(json.dumps(usage, indent=2))

if __name__ == "__main__":
    main()
