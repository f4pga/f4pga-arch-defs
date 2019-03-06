#!/usr/bin/env python3
from collections import namedtuple
from copy import deepcopy

import os
import logging

import json
import hashlib

# =============================================================================


class Connection(object):
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
        self.wire_pairs  = wire_pairs

    def copy(self):
        """
        Returns a copy of the rule

        :return:
        """
        return Connection(
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
        return Connection(
            conn["grid_deltas"],
            conn["tile_types"],
            conn["wire_pairs"]
        )

    def str_no_wires(self):
        """
        Returns a string that describes grid deltas and tile types.

        :return:
        """

        s  = "[%+d,%+d] " % tuple(self.grid_deltas)
        s += "<%s, %s> "  % tuple(self.tile_types)

        return s

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
        m.update(str.encode("".join([str(x) for x in self.tile_types]), "utf-8"))
        m.update(str.encode("".join([str(x) for x in self.wire_pairs]), "utf-8"))

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
        if other.grid_deltas[0] == -self.grid_deltas[0] or other.grid_deltas[1] == -self.grid_deltas[1]:
            if other.tile_types[0] == self.tile_types[1] and other.tile_types[1] == self.tile_types[0]:

                # Check if wire pairs are the same, but with swapped wires
                self_pairs  = set([pair[0] + "_" + pair[1] for pair in self.wire_pairs])
                other_pairs = set([pair[0] + "_" + pair[1] for pair in other.wire_pairs])

                return len(self_pairs - other_pairs) == 0

        # Connections are different
        return False

# =============================================================================


class ConnSplitter(object):
    """
    Connection rule splitter.

    When splitting a tile grid and creating new tile types the connection rules
    need to be updated accordingly. This class does that.
    """

    Loc  = namedtuple("Loc",  "x y")
    Conn = namedtuple("Conn", "grid_deltas tile_types wire_pairs")

    def __init__(self, db_root, db_overlay):
        """
        Constructor.

        :param db_root: Prjxray database root (input folder)
        :param db_overlay: Prjxray database overlay root (output folder)
        """

        self.db_root = db_root
        self.db_overlay = db_overlay

        self.tile_type_defs = {}

        self.bwd_tile_type_map = {} # FIXME: These are set externally for now. Content taken from GridSplitter
        self.fwd_tile_type_map = {}

        self.new_connections = set()

        # Input tileconn.json
        tileconn_file = os.path.join(db_root, "tileconn.json")
        if not os.path.isfile(tileconn_file):
            raise RuntimeError("Tile connection file '%s' not found!" % tileconn_file)
        self.tileconn_file = tileconn_file

        # Load connections
        self._load_tileconn()

    def _load_tileconn(self):
        """
        Loads tileconn.json and converts connection representation to internal format.

        :return:
        """

        # Load the tileconn file
        with open(self.tileconn_file, "r") as fp:
            rules = json.load(fp)
            self.old_connections = set([Connection.from_dict(c) for c in rules])

    def _load_tile_type(self, tile_type):
        """
        Loads tile type definition of a particular tile

        :param tile_type:
        :return:
        """

        file_name = os.path.join(self.db_root, "tile_type_%s.json" % tile_type)
        with open(file_name, "r") as fp:
            self.tile_type_defs[tile_type] = json.load(fp)

    def _get_tile_site_wires(self, tile_type):
        """
        Returns a list of wires that comes out of a tile which are relevant for
        each site in it.

        :param tile_type:
        :return:
        """

        # Load tile type
        file_name = os.path.join(self.db_root, "tile_type_%s.json" % tile_type)
        with open(file_name, "r") as fp:
            tile_type_def = json.load(fp)

        # Find wires relevant to sites
        tile_wires = set(tile_type_def["wires"])
        site_wires = {}

        #logging.debug("Tile type: '%s'" % tile_type)

        for site in tile_type_def["sites"]:

            # Get site name and pins
            name  = site["type"] + "_" + site["name"]
            wires = set(site["site_pins"].values())

            #logging.debug(" site name: '%s'" % name)

            relevant_wires = set()

            for wire in wires:

                # A driect connection from site to tile pin
                if wire in tile_wires:
                    relevant_wires.add(wire)
                    #logging.debug("  - %s" % wire)

                # Check if the wire goes through a pip
                for pip in tile_type_def["pips"].values():

                    if pip["src_wire"] == wire and pip["dst_wire"] in tile_wires:
                        relevant_wires.add(pip["dst_wire"])
                        #logging.debug("  + %s" % pip["dst_wire"])

                    if pip["dst_wire"] == wire and pip["src_wire"] in tile_wires:
                        relevant_wires.add(pip["src_wire"])
                        #logging.debug("  + %s" % pip["src_wire"])

            # Store
            site_wires[name] = relevant_wires

        return site_wires

    def _make_connections_between_splitted_tile_types(self):
        """
        Self explanatory.

        :return:
        """

        logging.info("Making connections between splitted tile types...")

        # Loop over all old tile types.
        old_tile_types = list(self.fwd_tile_type_map.keys())
        for old_tile_type in old_tile_types:

            # Loop over connection rules, collect all wires related to an old tile type
            all_wires = set()
            for rule in self.old_connections:

                # Only horizontal
                if rule.grid_deltas[1] != 0:
                    continue

                # The rule does not mention old tile type
                if rule.tile_types[0] != old_tile_type and rule.tile_types[1] != old_tile_type:
                    continue

                # Extract wires
                if rule.tile_types[0] == old_tile_type:
                    all_wires |= set([pair[0] for pair in rule.wire_pairs])
                if rule.tile_types[1] == old_tile_type:
                    all_wires |= set([pair[1] for pair in rule.wire_pairs])

            # Make new rules that connects the tile type that was split.
            rule = Connection(
                [1, 0],
                list(self.fwd_tile_type_map[old_tile_type]),
                [[wire, wire] for wire in all_wires]
            )

            self.new_connections.add(rule)

    def _make_connections_between_new_tile_types(self):
        """
        Self explanatory.

        :return:
        """

        rules = set()

        logging.info("Making connections between new tile types...")

        # Determine which wires are relevant for a particular site
        tile_site_wires = {}
        for old_tile_type in self.fwd_tile_type_map.keys():
            tile_site_wires[old_tile_type] = self._get_tile_site_wires(old_tile_type)
            #logging.debug(old_tile_type + " " + str(list(tile_site_wires[old_tile_type].keys())))

        # Change data structure
        tile_wires = {}
        for tile_name, site_wires in tile_site_wires.items():
            for site_name in site_wires.keys():
                new_tile_name = tile_name + "_" + site_name
                tile_wires[new_tile_name] = site_wires[site_name]
                #logging.debug(new_tile_name)

        # Loop over all old tile types.
        for old_tile_type_a in self.fwd_tile_type_map.keys():
            for old_tile_type_b in self.fwd_tile_type_map.keys():

                # Loop over all connection rules that are between old tile types
                for rule in self.old_connections:
                    if rule.tile_types[0] == old_tile_type_a and rule.tile_types[1] == old_tile_type_b:
                        rules.add(rule)
                    if rule.tile_types[0] == old_tile_type_b and rule.tile_types[1] == old_tile_type_a:
                        rules.add(rule)

        # Debug
        for rule in rules:
            if rule.grid_deltas[0] != 0 and rule.grid_deltas[1] != 0:
                logging.warning("Diagonal connection: " + rule.str_no_wires())

        # Process the rules
        new_rules = set()
        for rule in rules:

            # Vertical
            if rule.grid_deltas[0] == 0:

                # For each sub-tile
                for i in [0, 1]:
                    new_rule = rule.copy()
                    #logging.debug(new_rule.str_no_wires())

                    # Change tile types
                    new_rule.tile_types = [
                        self.fwd_tile_type_map[rule.tile_types[0]][i],
                        self.fwd_tile_type_map[rule.tile_types[1]][i],
                    ]

                    # Remove unnecessary wires
                    new_wire_pairs = []
                    wires_to_keep  = set(tile_wires[new_rule.tile_types[0]]) | set(tile_wires[new_rule.tile_types[1]])
                    for pair in new_rule.wire_pairs:
                        if pair[0] in wires_to_keep or pair[1] in wires_to_keep:
                            new_wire_pairs.append(pair)

                    assert(len(new_wire_pairs) != 0)
                    new_rule.wire_pairs = new_wire_pairs

                    #logging.debug(" " + new_rule.str_no_wires())
                    new_rules.add(new_rule)

            # Horizontal or diagonal
            else:
                new_rule = rule.copy()

                #logging.debug(new_rule.str_no_wires())

                if rule.grid_deltas[0] > 0:
                    left_tile  = self.fwd_tile_type_map[rule.tile_types[0]][1]
                    right_tile = self.fwd_tile_type_map[rule.tile_types[1]][0]
                    new_rule.tile_types = [left_tile, right_tile]

                if rule.grid_deltas[0] < 0:
                    left_tile  = self.fwd_tile_type_map[rule.tile_types[1]][1]
                    right_tile = self.fwd_tile_type_map[rule.tile_types[0]][0]
                    new_rule.tile_types = [right_tile, left_tile]

                #logging.debug(" " + new_rule.str_no_wires())
                new_rules.add(new_rule)
                #print(" ", new_rule.grid_deltas, new_rule.tile_types)

        # Merge new connections
        self.new_connections |= new_rules

    def _make_connections_between_new_and_old_tile_types(self):
        """
        Self explanatory.

        :return:
        """

        rules = set()

        logging.info("Making connections between new and old tile types...")

        # Loop over all old tile types.
        old_tile_types = list(self.fwd_tile_type_map.keys())
        for old_tile_type in old_tile_types:

            # Loop over all connection rules that mention old types
            for rule in self.old_connections:
                if rule.tile_types[0] == old_tile_type or rule.tile_types[1] == old_tile_type:
                    rules.add(rule)

        # Debug
        for rule in rules:
            if rule.grid_deltas[0] != 0 and rule.grid_deltas[1] != 0:
                logging.warning("Diagonal connection: " + rule.str_no_wires())

        # Process the rules
        new_rules = set()
        for rule in rules:

            # Vertical
            if rule.grid_deltas[0] == 0:
                # TODO: Skip for now. This type of connections will go outside ROI
                logging.warning("Skipping: " + rule.str_no_wires())

            # Horizontal or diagonal
            else:
                #logging.debug(rule.str_no_wires())

                new_rule = None

                # Left from splitted tile
                if rule.grid_deltas[0] < 0 and rule.tile_types[0] in old_tile_types:
                    new_rule = rule.copy()
                    new_tile_type = self.fwd_tile_type_map[rule.tile_types[0]][0]  # Left
                    new_rule.tile_types[0] = new_tile_type

                # Right to splitted tile
                if rule.grid_deltas[0] > 0 and rule.tile_types[1] in old_tile_types:
                    new_rule = rule.copy()
                    new_tile_type = self.fwd_tile_type_map[rule.tile_types[1]][0]  # Left
                    new_rule.tile_types[1] = new_tile_type

                # Right from splitted tile
                if rule.grid_deltas[0] > 0 and rule.tile_types[0] in old_tile_types:
                    new_rule = rule.copy()
                    new_tile_type = self.fwd_tile_type_map[rule.tile_types[0]][1]  # Right
                    new_rule.tile_types[0] = new_tile_type

                # Right to splitted tile
                if rule.grid_deltas[0] < 0 and rule.tile_types[1] in old_tile_types:
                    new_rule = rule.copy()
                    new_tile_type = self.fwd_tile_type_map[rule.tile_types[1]][1]  # Right
                    new_rule.tile_types[1] = new_tile_type

                if new_rule is not None:
                    new_rules.add(new_rule)
                    #logging.debug(" " + new_rule.str_no_wires())

        # Merge new connections
        self.new_connections |= new_rules

    def _purge_connections(self):
        """
        Removes connection rules that refer to "OLD" tile types.

        :return:
        """

        rules_to_remove = set()

        # Loop over all old tile types.
        old_tile_types = list(self.fwd_tile_type_map.keys())
        for old_tile_type in old_tile_types:

            # Loop over all connection rules that mention old types
            for rule in self.new_connections:
                if rule.tile_types[0] == old_tile_type or rule.tile_types[1] == old_tile_type:
                    rules_to_remove.add(rule)
                    logging.warning("Removing: " + rule.str_no_wires())

        # Remove the rules
        self.new_connections -= rules_to_remove

    def split(self):
        """
        Triggers the split.

        :return:
        """

        self._make_connections_between_splitted_tile_types()
        self._make_connections_between_new_tile_types()
        self._make_connections_between_new_and_old_tile_types()

        self.new_connections |= self.old_connections

        self._purge_connections()

        # Save tile connections
        connections = [c.__dict__() for c in self.new_connections]

        file_name = os.path.join(self.db_overlay, "tileconn.json")
        logging.info("Writing '%s'" % file_name)

        with open(file_name, "w") as fp:
            json.dump(connections,  fp, sort_keys=True, indent=1)
            fp.flush()
