#!/usr/bin/env python3
import unittest

from connection import Rule

# =============================================================================

class TestRule(unittest.TestCase):

    def setUp(self):

        self.rule1 = Rule(
            [1, 0],
            ["TILE_TYPE_A", "TILE_TYPE_B"],
            [
                ["WIRE_3", "WIRE_X"],
                ["WIRE_2", "WIRE_Y"],
                ["WIRE_1", "WIRE_Z"],
                ["WIRE_0", "WIRE_W"],
            ]
        )

        self.rule2 = Rule(
            [-1, 0],
            ["TILE_TYPE_B", "TILE_TYPE_A"],
            [
                ["WIRE_X", "WIRE_3"],
                ["WIRE_Y", "WIRE_2"],
                ["WIRE_Z", "WIRE_1"],
                ["WIRE_W", "WIRE_0"],
            ]
        )

        self.rule3 = Rule(
            [-1, 0],
            ["TILE_TYPE_B", "TILE_TYPE_A"],
            [
                ["WIRE_X", "WIRE_3"],
                ["WIRE_Y", "WIRE_2"],
                ["WIRE_Z", "WIRE_1"],
                ["WIRE_U", "WIRE_4"],
            ]
        )

    def test_wire_sort(self):

        self.assertEqual(self.rule1.wire_pairs,
            [['WIRE_0', 'WIRE_W'], ['WIRE_1', 'WIRE_Z'], ['WIRE_2', 'WIRE_Y'], ['WIRE_3', 'WIRE_X']]
        )

    def test_eq(self):

        res = self.rule1 == self.rule2
        self.assertTrue(res)

    def test_neq(self):

        res = self.rule1 != self.rule3
        self.assertTrue(res)

# =============================================================================

if __name__ == '__main__':
    unittest.main()

