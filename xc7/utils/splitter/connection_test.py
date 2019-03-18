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
                ["WIRE_Z", "WIRE_1"],
                ["WIRE_X", "WIRE_3"],
                ["WIRE_Y", "WIRE_2"],
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


        self.rule4 = Rule(
            [-1, -1],
            ["TILE_TYPE_B", "TILE_TYPE_A"],
            [
                ["WIRE_U", "WIRE_4"],
                ["WIRE_Y", "WIRE_2"],
                ["WIRE_Z", "WIRE_1"],
                ["WIRE_X", "WIRE_3"],
            ]
        )

        self.rule5 = Rule(
            [+1, +1],
            ["TILE_TYPE_A", "TILE_TYPE_B"],
            [
                ["WIRE_3", "WIRE_X"],
                ["WIRE_1", "WIRE_Z"],
                ["WIRE_2", "WIRE_Y"],
                ["WIRE_4", "WIRE_U"],
            ]
        )

        self.rule6 = Rule(
            [+1, -1],
            ["TILE_TYPE_A", "TILE_TYPE_B"],
            [
                ["WIRE_X", "WIRE_3"],
                ["WIRE_Y", "WIRE_2"],
                ["WIRE_Z", "WIRE_1"],
                ["WIRE_U", "WIRE_4"],
            ]
        )

        self.rule7 = Rule(
            [+1, -1],
            ["TILE_TYPE_A", "TILE_TYPE_B"],
            [
                ["WIRE_X", "WIRE_3"],
                ["WIRE_Y", "WIRE_2"],
                ["WIRE_Z", "WIRE_1"],
                ["WIRE_U", "WIRE_4"],
                ["WIRE_V", "WIRE_5"],
            ]
        )

#        print("Hashes:")
#        print(hash(self.rule1))
#        print(hash(self.rule2))
#        print(hash(self.rule3))
#        print(hash(self.rule4))
#        print(hash(self.rule5))
#        print(hash(self.rule6))
#        print(hash(self.rule7))


#    def test_wire_sort(self):

#        self.assertEqual(self.rule1.wire_pairs,
#            [['WIRE_0', 'WIRE_W'], ['WIRE_1', 'WIRE_Z'], ['WIRE_2', 'WIRE_Y'], ['WIRE_3', 'WIRE_X']]
#        )

#        self.assertEqual(self.rule2.wire_pairs,
#            [['WIRE_W', 'WIRE_0'], ['WIRE_Z', 'WIRE_1'], ['WIRE_Y', 'WIRE_2'], ['WIRE_X', 'WIRE_3']]
#        )

    def test_eq(self):

        self.assertEqual(self.rule1, self.rule2)
        self.assertEqual(self.rule4, self.rule5)

    def test_neq(self):

        self.assertNotEqual(self.rule1, self.rule3)
        self.assertNotEqual(self.rule4, self.rule6)
        self.assertNotEqual(self.rule6, self.rule7)
        self.assertNotEqual(self.rule7, self.rule6)


# =============================================================================

if __name__ == '__main__':
    unittest.main()

