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

import re

USAGE_PATTERN = re.compile(
    r'^Netlist\s(?P<type>[A-Za-z0-9_-]+)\sblocks:\s(?P<count>[0-9]+)'
)


def parse_usage(pack_log):
    """ Yield (block, count) from pack_log file.

    Args:
        pack_log (str): Path pack.log file generated from VPR.

    Yields:
        (block, count): Tuple of block name and count of block type.

    """
    with open(pack_log) as f:
        for line in f:
            m = re.match(USAGE_PATTERN, line.strip())
            if m:
                yield (m.group("type"), int(m.group("count")))
