#!/usr/bin/env python3
# Run: python3 -m unittest ice40.utils.fasm_icebox.tests.test_fasm_icebox_utils

import unittest
from .. import fasm_icebox_utils
from ..ice40_feature import Feature, FasmEntry, IceDbEntry


class TestConversion(unittest.TestCase):
    def helper(self, icedb, fasm_repr):
        fi = Feature.from_icedb_entry(icedb)
        ff = Feature.from_fasm_entry(fasm_repr)
        self.assertEqual(fasm_repr, fi.to_fasm_entry())
        self.assertEqual(icedb, ff.to_icedb_entry())

    def test_lc_x_lut(self):
        test_vec = [xx for xx in range(20)]
        lut, ctrl = fasm_icebox_utils._lc_to_lut(test_vec)
        lc = fasm_icebox_utils._lut_to_lc(lut, ctrl)
        self.assertEqual(lc, test_vec)

    def test_nibble_x_bits(self):
        test_vec = "0123456789abcd"
        bits = fasm_icebox_utils._nibbles_to_bits(test_vec)
        nibbles = fasm_icebox_utils._bits_to_nibbles(bits)
        self.assertEqual(nibbles, test_vec)

    def test_ram(self):

        self.helper(
            IceDbEntry("RAMB", [3, 15], ["B10[49]"], ["INITA"], 49),
            FasmEntry("RAMB_X3_Y15.INITA[49]", ["10_49"]),
        )

        self.helper(
            IceDbEntry("RAMB", [3, 15], ["!B10[49]"], ["INITA"], 49),
            FasmEntry("RAMB_X3_Y15.INITA[49]", ["!10_49"]),
        )

    def test_logic(self):
        self.helper(
            IceDbEntry(
                "LOGIC",
                [7, 3],
                ["!B0[31]", "B0[32]", "!B0[33]", "!B0[34]", "!B1[31]"],
                ["buffer", "carry_in_mux", "lutff_0/in_3"],
                None,
            ),
            FasmEntry(
                "LOGIC_X7_Y3.buffer.carry_in_mux.lutff_0_in_3",
                "!0_31 0_32 !0_33 !0_34 !1_31".split(),
            ),
        )

    def test_io(self):
        self.helper(
            IceDbEntry(
                "IO",
                [10, 17],
                ["B1[17]"],
                ["buffer", "io_0/D_IN_0", "span12_horz_0"],
                None,
            ),
            FasmEntry("IO_X10_Y17.buffer.io_0_D_IN_0.span12_horz_0", ["1_17"]),
        )


if __name__ == "__main__":
    unittest.main()
