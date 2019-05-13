#!/usr/bin/env python3
"""
This file is responsible for running a series of tests for the V2X itself.
For now it helps to test sanity checks of FASM features.
"""

import sys
import os
import re

from argparse import Namespace

# =============================================================================

# Get the source file path
src_path = os.path.dirname(os.path.realpath(__file__))

# Import V2X
v2x_path = os.path.realpath(os.path.join(src_path, "../../"))
sys.path.append(v2x_path)

import vlog_to_pbtype

# =============================================================================


def call_v2x(verilog_file):
    """
    Runs the V2X. Returns its exitcode
    """

    verilog_file = os.path.join(src_path, verilog_file)

    # Setup basic argument mockup
    args = {
        "infiles": [verilog_file],
        "includes": "",
        "top": "top",
        "outfile": "pb_type.xml",
        "dump_json": False
    }

    # Run V2X
    try:
        vlog_to_pbtype.main(Namespace(**args))

    # Got an 'exit()' call
    except SystemExit as ex:

        # Return the code
        if ex.code is not None:
            return ex.code
        else:
            return 0

    # Got any other exception, return -1
    except Exception as ex:
        print("EXCEPTION:", repr(ex))
        return -1

    # Return success
    return 0


def run_tests():
    """
    Runs V2X for all verilog files wihch names match a specific pattern.
    It is expected that the V2X fail for each of them. Returns 0 if tests
    were successful (all failures) and -1 otherwise.
    """

    # List verilog files which contain tests
    all_files = os.listdir(src_path)
    verilog_files = [f for f in all_files if re.match("^[0-9]+.*.v$", f)]
    verilog_files = sorted(verilog_files)

    # Run them one by one
    results = []
    for f in verilog_files:

        if call_v2x(f) != 0:
            results.append(True)
            print("[V] {}".format(f))
        else:
            results.append(False)
            print("[X] {}".format(f))

    # Cleanup
    try:
        os.remove("pb_type.xml")
    except FileNotFoundError:
        pass

    return 0 if all(results) else -1


# =============================================================================


if __name__ == "__main__":
    exit(run_tests())
