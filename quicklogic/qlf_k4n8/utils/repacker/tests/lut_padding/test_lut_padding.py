#!/usr/bin/env python3
import sys
import os
import tempfile

import pytest

sys.path.append(os.path.join(os.path.dirname(__file__), "..", ".."))
from repack import main as repack_main  # noqa: E402

# =============================================================================


@pytest.mark.parametrize(
    "lut_width, lut_inputs", [
        ("1", "0"),
        ("1", "1"),
        ("1", "2"),
        ("1", "3"),
    ]
)
def test_lut_padding(monkeypatch, lut_width, lut_inputs):
    """
    Tests repacking of a single lut with some inputs unconnected. Verifies
    results against golden references.
    """

    basedir = os.path.dirname(__file__)

    qlfpga_plugins = os.path.join(
        basedir, "..", "..", "..", "..", "..", "..", "third_party",
        "qlfpga-symbiflow-plugins"
    )

    vpr_arch = os.path.join(
        qlfpga_plugins, "qlf_k4n8/vpr_arch/UMC22nm_vpr.xml"
    )
    repacking_rules = os.path.join(
        qlfpga_plugins, "qlf_k4n8/vpr_arch/repacking_rules.json"
    )

    eblif_ref = os.path.join(
        basedir, "lut{}_{}.golden.eblif".format(lut_width, lut_inputs)
    )
    eblif_in = os.path.join(basedir, "lut{}.eblif".format(lut_width))
    net_in = os.path.join(
        basedir, "lut{}_{}.net".format(lut_width, lut_inputs)
    )

    with tempfile.TemporaryDirectory() as tempdir:

        eblif_out = os.path.join(tempdir, "out.eblif")
        net_out = os.path.join(tempdir, "out.net")

        # Substitute commandline arguments
        monkeypatch.setattr(
            "sys.argv", [
                "repack.py",
                "--vpr-arch",
                vpr_arch,
                "--repacking-rules",
                repacking_rules,
                "--eblif-in",
                eblif_in,
                "--net-in",
                net_in,
                "--eblif-out",
                eblif_out,
                "--net-out",
                net_out,
            ]
        )

        # Invoke the repacker
        repack_main()

        # Compare output with the golden reference
        with open(eblif_ref, "r") as fp:
            golden_data = fp.read().rstrip()
        with open(eblif_out, "r") as fp:
            output_data = fp.read().rstrip()

        assert golden_data == output_data
