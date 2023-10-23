"""Tool for generating a comparision CSV between multiple usage.json files.

utils/gather_usage.py should be used to generate usage.json in various
configurations for comparision.

"""
import argparse
import json
import os.path


def main():
    parser = argparse.ArgumentParser(description=__doc__)

    parser.add_argument(
        'usage_json',
        nargs='+',
        help="usage.json files generated from gather_usage.py"
    )

    args = parser.parse_args()

    blocks = set()
    bases = set()
    targets = {}

    for filename in args.usage_json:
        with open(filename) as f:
            _, x = os.path.split(filename)
            base, _ = os.path.splitext(x)

            assert base not in bases, base
            bases.add(base)

            j = json.load(f)

            for target, usage in j.items():
                if target not in targets:
                    targets[target] = {}
                    for block in usage['usage']:
                        targets[target][block] = {}

                for block in usage['usage']:
                    blocks.add(block)
                    targets[target][block][base] = usage['usage'][block]

    for v in targets.values():
        for block in blocks:
            if block not in v:
                v[block] = {}

    row1 = ['']
    row2 = ['']
    for block in sorted(blocks):
        row1.append(block)
        for _ in range(len(bases) - 1):
            row1.append('')

        for base in sorted(bases):
            row2.append(base)

    print(','.join(row1))
    print(','.join(row2))

    for target in sorted(targets):
        row = [target]

        for block in sorted(blocks):
            counts = targets[target][block]

            for base in sorted(bases):
                if base in counts:
                    row.append(str(counts[base]))
                else:
                    row.append('0')

        print(','.join(row))


if __name__ == "__main__":
    main()
