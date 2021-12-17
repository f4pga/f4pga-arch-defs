#!/usr/bin/env python3
import re

PATTERNS = {
    "cpd":
        re.compile(
            r"Final critical path delay \(least slack\):\s(?P<val>[0-9.]+)"
        ),
    "fmax":
        re.compile(r".*Fmax:\s(?P<val>[0-9.]+)"),
    "swns":
        re.compile(
            r"Final setup Worst Negative Slack \(sWNS\):\s(?P<val>[0-9.-]+)"
        ),
    "stns":
        re.compile(
            r"Final setup Total Negative Slack \(sTNS\):\s(?P<val>[0-9.-]+)"
        ),
}


def parse_timing(route_log):
    """
    Parses VPR route log and extracts relevant timing information. Returns a
    dict with the data.
    """

    timing = {}

    with open(route_log, "r") as fp:
        for line in fp:

            line = line.strip()
            if not line:
                continue

            for key, pattern in PATTERNS.items():
                match = pattern.match(line)
                if match is not None:
                    assert key not in timing, key
                    timing[key] = float(match.group("val"))

    return timing
