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
        self.wire_pairs  = sorted(wire_pairs, key=lambda pair: "".join(sorted(pair)))

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

        # Hash 1
        m = hashlib.sha256()
        m.update(str.encode(self.tile_types[0] + self.tile_types[1],  "utf-8"))
        m.update(str.encode("".join([str(+x) for x in self.grid_deltas]), "utf-8"))
        m.update(str.encode("".join([x[0] + x[1] for x in self.wire_pairs]), "utf-8"))
        h1 = hash(m.digest())

        # Hash 2
        m = hashlib.sha256()
        m.update(str.encode(self.tile_types[1] + self.tile_types[0],  "utf-8"))
        m.update(str.encode("".join([str(-x) for x in self.grid_deltas]), "utf-8"))
        m.update(str.encode("".join([x[1] + x[0] for x in self.wire_pairs]), "utf-8"))
        h2 = hash(m.digest())

        # Select one
        if h1 > h2:
            return h1
        else:
            return h2

    def __eq__(self, other):
        """
        Equality operator

        :param other:
        :return:
        """

        # Compare hashes
        return hash(self) == hash(other)

