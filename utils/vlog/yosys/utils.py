#!/usr/bin/env python3
import re

"""The JSON Yosys outputs isn't acutally compliant JSON, as it contains C-style
comments. These must be stripped."""

def strip_yosys_json(text):
    stripped = re.sub(r'\\\n', '', text)
    stripped = re.sub(r'//.*\n', '\n', stripped)
    stripped = re.sub(r'/\*.*\*/', '', stripped)
    return stripped
