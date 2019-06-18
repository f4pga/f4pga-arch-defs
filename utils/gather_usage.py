""" Tool for collecting usage statistic on a build tree.

The filter can be used to gather usage on specific build variants.

"""
import argparse
import re
import json
import os
from lib.parse_usage import parse_usage


def main():
    parser = argparse.ArgumentParser(
        description="Walks tree and gathers usage numbers from pack.log."
    )

    parser.add_argument(
        '--root_dir',
        required=True,
        help="Root directory to scan for pack.log files."
    )
    parser.add_argument(
        '--filter',
        required=True,
        help=  # noqa: E251
        "Python regular expression used to filter the complete path to pack.log files."
    )

    args = parser.parse_args()

    filt = re.compile(args.filter)

    usage_logs = {}

    for root, dirs, files in os.walk(args.root_dir):
        if 'pack.log' not in files:
            continue

        pack_log = os.path.join(root, 'pack.log')

        if not filt.search(pack_log):
            continue

        parent_dir, _ = os.path.split(pack_log)
        pparent_dir, device_tuple = os.path.split(parent_dir)
        _, target = os.path.split(pparent_dir)

        usage_logs[target] = {
            'path': parent_dir,
            'device_tuple': device_tuple,
            'usage': dict(parse_usage(pack_log)),
        }

    print(json.dumps(usage_logs, indent=2))


if __name__ == "__main__":
    main()
