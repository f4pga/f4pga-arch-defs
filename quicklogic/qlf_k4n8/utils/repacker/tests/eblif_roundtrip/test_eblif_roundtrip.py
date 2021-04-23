#!/usr/bin/env python3
import os
import sys
import tempfile

sys.path.append(os.path.join(os.path.dirname(__file__), "..", ".."))
from eblif_netlist import Eblif  # noqa: E402

# =============================================================================


def test_netlist_roundtrip():

    basedir = os.path.dirname(__file__)
    golden_file = os.path.join(basedir, "netlist.golden.eblif")

    # Load and parse the EBLIF file
    eblif = Eblif.from_file(golden_file)

    with tempfile.TemporaryDirectory() as tempdir:

        # Write the EBLIF back
        output_file = os.path.join(tempdir, "netlist.output.eblif")
        eblif.to_file(output_file)

        # Compare the two files
        with open(golden_file, "r") as fp:
            golden_data = fp.read().rstrip()
        with open(output_file, "r") as fp:
            output_data = fp.read().rstrip()

        assert golden_data == output_data
