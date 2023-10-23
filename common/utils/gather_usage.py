""" Tool for collecting usage statistic on a build tree.

The filter can be used to gather usage on specific build variants.

"""
import argparse
import re
import json
import os


def main():
    parser = argparse.ArgumentParser(
        description="Walks tree and gathers usage from block_usage files."
    )

    parser.add_argument(
        '--root_dir',
        required=True,
        help="Root directory to scan for block_usage.json files."
    )
    parser.add_argument(
        '--filter',
        required=True,
        help=  # noqa: E251
        "Python regular expression used to filter the complete path to block_usage.json files."
    )

    args = parser.parse_args()

    filt = re.compile(args.filter)

    usage_logs = {}

    for root, dirs, files in os.walk(args.root_dir):
        if 'block_usage.json' not in files:
            continue

        block_usage_json = os.path.join(root, 'block_usage.json')

        if not filt.search(block_usage_json):
            continue

        with open(block_usage_json):
            block_usage = json.loads(block_usage_json)

        parent_dir, _ = os.path.split(block_usage_json)
        pparent_dir, device_tuple = os.path.split(parent_dir)
        _, target = os.path.split(pparent_dir)

        usage_logs[target] = {
            'path': parent_dir,
            'device_tuple': device_tuple,
            'usage': block_usage['blocks'],
        }

    print(json.dumps(usage_logs, indent=2))


if __name__ == "__main__":
    main()
