#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#
# Copyright (C) 2020-2022 F4PGA Authors.
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
"""
Extracts timing information from VPR timing_summary.json and
reports it or verifies the information against expressions passed in
--assert argument.
It is used in ASSERT_TIMING test cases to catch any regressions to design
implementation that would affect timing.
"""
import argparse
import json
import re

ASSERT_SPEC = re.compile(
    r"(?P<param>[A-Za-z0-9_-]+)(?P<op>=|<|<=|>=|>)(?P<val>[0-9.-]+)"
)


def main():
    parser = argparse.ArgumentParser(
        description="Converts VPR timing_summary.json into timing report data"
    )
    parser.add_argument('timing_summary')
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

    with open(args.timing_summary) as f:
        timing = json.load(f)

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
