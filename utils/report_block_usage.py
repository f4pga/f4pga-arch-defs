#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#
# Copyright 2020-2022 F4PGA Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# SPDX-License-Identifier: Apache-2.0
#
"""
Extracts block usage information from VPR block usage json summary and
reports it or verifies the information against expressions passed in
--assert-usage argument.
It is used in ASSERT_BLOCK_TYPES_ARE_USED test cases to catch any regressions
to design implementation that would affect block usage.
"""

import argparse
import json
import re

USAGE_SPEC = re.compile(
    r"(?P<type>[A-Za-z0-9_-]+)(?P<op>=|<|<=|>=|>)(?P<val>[0-9]+)"
)


def main():
    parser = argparse.ArgumentParser(
        description="Converts VPR block_usage.json into usage numbers."
    )
    parser.add_argument('block_usage')
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

    with open(args.block_usage) as f:
        usage_report = json.load(f)
    usage = usage_report['blocks']

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
