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
This script parses and then compares contents of two PCF files. If the
constraints are identical exits with code 0. Otherwise prints parsed content
of both files and exits with -1. It is used to verify whether
design constraints were correctly applied during the toolchain flow.
fasm2bels for QuickLogic PP3 architecture can write PCF with actual
IO locations as encoded in the bitstream. This is verified against
the original PCF from the design.
"""
import argparse

from f4pga.aux.utils.pcf import parse_simple_pcf


def main():
    parser = argparse.ArgumentParser(
        description="Compares IO constraints across two PCF files"
    )
    parser.add_argument("pcf", nargs=2, type=str, help="PCF files")
    args = parser.parse_args()

    # Read constraints, convert them to tuples for easy comparison
    pcf = []
    for i in [0, 1]:
        with open(args.pcf[i], "r") as fp:
            constrs = set()
            for constr in parse_simple_pcf(fp):
                key = tuple(
                    [
                        type(constr).__name__, constr.net,
                        None if not hasattr(constr, "pad") else constr.pad
                    ]
                )
                constrs.add(key)
            pcf.append(constrs)

    # We have a match
    if pcf[0] == pcf[1]:
        exit(0)

    # Print difference
    print("PCF constraints mismatch!")
    for i in [0, 1]:
        print("'{}'".format(args.pcf[i]))
        for key in sorted(pcf[i]):
            print("", key)

    exit(-1)


if __name__ == "__main__":
    main()
