#!/usr/bin/env python3
from collections import namedtuple
from copy import deepcopy

import os
import logging

import json
import hashlib

# =============================================================================


class Rule(object):
    """
    This class represents a connection rule as stored in tileconnn.json file.
    Connections are hashable and can be compared using the '==' operator.
    """

    def __init__(self, grid_deltas, tile_types, wire_pairs):
        """
        Constructor.

        :param grid_deltas:
        :param tile_types:
        :param wire_pairs:
        """

        self.grid_deltas = grid_deltas
        self.tile_types  = tile_types
        self.wire_pairs  = sorted(wire_pairs, key=lambda pair: pair[0] + ":" + pair[1])

    def copy(self):
        """
        Returns a deep copy of the rule

        :return:
        """
        return Rule(
            deepcopy(self.grid_deltas),
            deepcopy(self.tile_types),
            deepcopy(self.wire_pairs)
        )

    @staticmethod
    def from_dict(conn):
        """
        Builds a Connection object from dict

        :param conn:
        :return:
        """
        return Rule(
            conn["grid_deltas"],
            conn["tile_types"],
            conn["wire_pairs"]
        )

    def __dict__(self):
        """
        Builds a dict from the object

        :return:
        """
        return {
            "grid_deltas": self.grid_deltas,
            "tile_types":  self.tile_types,
            "wire_pairs":  self.wire_pairs
        }

    def str_no_wires(self):
        """
        Returns a string that describes grid deltas and tile types.

        :return:
        """

        s  = "[%+d,%+d] " % tuple(self.grid_deltas)
        s += "<%s, %s> "  % tuple(self.tile_types)

        return s

    def __str__(self):
        """
        Full stringification.

        :return:
        """

        s  = "[%+d,%+d] " % tuple(self.grid_deltas)
        s += "<%s, %s> "  % tuple(self.tile_types)
        s += str(self.wire_pairs)

        return s

    def __hash__(self):
        """
        Computes hash (for comparison).

        :return:
        """

        m = hashlib.sha256()

        m.update(str.encode("".join([str(x) for x in self.grid_deltas]), "utf-8"))
        m.update(str.encode("".join([str(x) for x in self.tile_types]),  "utf-8"))
        m.update(str.encode("".join([str(x) for x in self.wire_pairs]),  "utf-8"))

        return hash(m.digest())

    def __eq__(self, other):
        """
        Equality operator

        :param other:
        :return:
        """

        # Hashes are equal, so are the rules
        if hash(self) == hash(other):
            return True

        # Check permutation
        if other.grid_deltas[0] == -self.grid_deltas[0] and other.grid_deltas[1] == -self.grid_deltas[1]:
            if other.tile_types[0] == self.tile_types[1] and other.tile_types[1] == self.tile_types[0]:

                # Check if wire pairs are the same, but with swapped wires
                self_pairs  = set([pair[0] + ":" + pair[1] for pair in self.wire_pairs])
                other_pairs = set([pair[1] + ":" + pair[0] for pair in other.wire_pairs])

                return len(self_pairs - other_pairs) == 0

        # Connections are different
        return False

