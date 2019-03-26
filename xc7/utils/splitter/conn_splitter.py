#!/usr/bin/env python3
import argparse

from collections import namedtuple
from copy import deepcopy

import os
import logging

import json
import hashlib

from connection import Rule
from connection import ExtendedRule


# =============================================================================


class ConnSplitter(object):
    """
    Connection rule splitter.

    When splitting a tile grid and creating new tile types the connection rules
    need to be updated accordingly. This class does that.
    """

    Loc  = namedtuple("Loc",  "x y")
    Conn = namedtuple("Conn", "grid_deltas tile_types wire_pairs")

    def __init__(self, db_root, db_overlay, tile_types):
        """
        Constructor.

        :param db_root: Prjxray database root (input folder)
        :param db_overlay: Prjxray database overlay root (output folder)
        """

        self.db_root = db_root
        self.db_overlay = db_overlay

        self.tile_types = tile_types

        self.new_connections = set()
        self.ext_connections = []

        # Load the old (original) tilegrid file
        file_name = os.path.join(db_root, "tilegrid.json")
        with open(file_name, "r") as fp:
            self.old_grid_by_tile = json.load(fp)

        self.old_grid_by_loc = {}
        for tile_name, tile in self.old_grid_by_tile.items():
            tile_loc = self.Loc(tile["grid_x"], tile["grid_y"])
            self.old_grid_by_loc[tile_loc] = tile_name

        # Load the new (split) tilegrid file
        file_name = os.path.join(db_overlay, "tilegrid.json")
        with open(file_name, "r") as fp:
            self.new_grid_by_tile = json.load(fp)

        # Load the original tileconn file
        file_name = os.path.join(db_root, "tileconn.json")
        with open(file_name, "r") as fp:
            rules = json.load(fp)
            self.connections = set([Rule.from_dict(c) for c in rules])

        # Load tile type map
        file_name = os.path.join(db_overlay, "map_tile_types.json")
        with open(file_name, "r") as fp:
            tile_type_map = json.load(fp)
            self.fwd_tile_type_map = tile_type_map["forward"]

        # Load tile wire map
        file_name = os.path.join(db_overlay, "wire_name_map.json")
        with open(file_name, "r") as fp:
            self.fwd_tile_wire_map = json.load(fp)

        # Build new tile type list
        self.new_tile_types = set()
        for new_tile_types in self.fwd_tile_type_map.values():
            self.new_tile_types |= set(new_tile_types)
        self.new_tile_types = list(self.new_tile_types)

        # FIXME: These are hard-coded rules for carry chains
        self.hard_coded_rules = []
        for new_tile_type in self.new_tile_types:

            # Carry chain between SLICEs
            self.hard_coded_rules.append({
                "grid_deltas": [0, 1],
                "tile_types":  [new_tile_type, new_tile_type],
                "wire_pairs": [
                    ["SITE_COUT", "SITE_CIN"],
                ]
            })

            # Carry chains between SLICEs through HCLK down
            self.hard_coded_rules.append({
                "grid_deltas": [0, 1],
                "tile_types": [new_tile_type, "HCLK_CLB"],
                "wire_pairs": [
                    ["SITE_COUT", "HCLK_CLB_COUT0_L"],
                ]
            })

            # Carry chains between SLICEs through HCLK up
            self.hard_coded_rules.append({
                "grid_deltas": [0, 1],
                "tile_types": ["HCLK_CLB", new_tile_type],
                "wire_pairs": [
                    ["HCLK_CLB_COUT0_L", "SITE_CIN"],
                ]
            })

    def _get_wires_between_tiles(self, grid_deltas, tile_types):
        """
        Returns a list of wire paris which connect two tile types with
        the gives spatial relation (grid_deltas).

        :param grid_deltas:
        :param tile_types:
        :return:
        """

        wire_pairs = []

        # Check all the connection rules (old ones)
        for rule in self.connections:

            # Straightforward
            if rule.grid_deltas[0] == +grid_deltas[0] and rule.grid_deltas[1] == +grid_deltas[1]:
                if rule.tile_types[0] == tile_types[0] and rule.tile_types[1] == tile_types[1]:
                    wire_pairs.extend(rule.wire_pairs)

            # Reversed
            if rule.grid_deltas[0] == -grid_deltas[0] and rule.grid_deltas[1] == -grid_deltas[1]:
                if rule.tile_types[0] == tile_types[1] and rule.tile_types[1] == tile_types[0]:
                    wire_pairs.extend([[pair[1], pair[0]] for pair in rule.wire_pairs])

        return wire_pairs

    def _build_tile_pattern(self, loc):
        """
        Build a tile pattern starting from a given location on the grid. Try
        to extend the pattern in left and right direction until no more tiles
        of interest are found. Add one more left and right tile to allow proper
        connection definition to them.

        :param loc:
        :return:
        """

        # Returns tile type at given location on the grid.
        def tile_type_at_loc(loc):
            tile_name = self.old_grid_by_loc[loc]
            return self.old_grid_by_tile[tile_name]["type"]

        # Add the first tile.
        tile_types = [tile_type_at_loc(loc)]

        # Check tile types left add them consecutively
        for dx in range(1, 3):

            # Get tile type. Break on exception (no more tiles in row)
            try:
                tile_type = tile_type_at_loc(self.Loc(loc.x - dx, loc.y))
            except KeyError:
                break

            # If it is a tile of interest then add it (prepend). If it is not then add it and break
            tile_types.insert(0, tile_type)

            if tile_type not in self.tile_types:
                break

        # Check tile types right add them consecutively
        for dx in range(1, 3):

            # Get tile type. Break on exception (no more tiles in row)
            try:
                tile_type = tile_type_at_loc(self.Loc(loc.x + dx, loc.y))
            except KeyError:
                break

            # If it is a tile of interest then add it (append). If it is not then add it and break
            tile_types.append(tile_type)

            if tile_type not in self.tile_types:
                break

        # Return the list as tuple (is hashable)
        return tuple(tile_types)

    def _identify_tile_patterns(self):
        """
        Loop over the original grid and find repeating layout patterns which
        contain one or mode tile type of interest. Limit the search to
        horizontal patterns only as only those are relevant.
        :return:
        """

        patterns = set()

        # Loop over the grid, search for any tile of interest
        for tile_loc, tile_name in self.old_grid_by_loc.items():

            # Check if we have hit an old tile type. If so then start a pattern.
            tile_type = self.old_grid_by_tile[tile_name]["type"]
            if tile_type in self.tile_types:

                # Build a pattern
                pat = self._build_tile_pattern(tile_loc)
                patterns.add(pat)

        # In 7-series we can have only a single or two columns of CLBs.
        # So only "xCx" and "xCCx" patterns are possible, where "x" denotes
        # Any tile type and "C" denotes a CLB tile type.
        #
        # Do a simple check to ensure that all patterns meet these criteria.
        for pattern in patterns:
            is_ok = True

            # Check length
            if len(pattern) != 3 and len(pattern) != 4:
                is_ok = False

            # The pattern is wrong
            if not is_ok:
                logging.critical("Unexpected tile pattern:")
                logging.critical(str(pattern))
                raise RuntimeError("Unexpected tile pattern")

        return patterns

    def _process_tile_patterns(self):
        """
        Process tile patterns which consist of old tile types. Generate
        extended connection rules for each of them
        :return:
        """

        # Process each tile pattern
        for pattern in self.old_conn_patterns:

            # Initialize a new extended connection rule that will serve
            # the pattern
            ext_rule = {
                "grid_deltas": [],
                "tile_types":  [],
                "connections": [],
            }

            # Tile types
            for tile_type in pattern:
                if tile_type in self.tile_types:
                    ext_rule["tile_types"].extend(self.fwd_tile_type_map[tile_type])
                else:
                    ext_rule["tile_types"].append(tile_type)

            # Grid deltas
            for x in range(len(ext_rule["tile_types"])):
                ext_rule["grid_deltas"].append([x, 0])

            # Debug
            logging.debug(str(pattern))
            logging.debug(str(ext_rule["grid_deltas"]))
            logging.debug(str(ext_rule["tile_types"]))

            N = len(pattern)
            M = len(ext_rule["tile_types"])

            # ...................................
            # Connection between tiles 0 and 1. Just re-map right wires
            i0 = 0
            j0 = 0
            new_wire_pairs = []
            for pair in self._get_wires_between_tiles([1, 0], [pattern[i0], pattern[i0+1]]):
                wire = self.fwd_tile_wire_map[pair[1]]  # Map to new name
                wire = wire.replace("X0Y0", "SITE")     # X0Y0 goes to site of the tile
                wire = wire.replace("X1Y0", "PASS")     # X1Y0 goes through the tile
                new_wire_pairs.append([pair[0], wire])

            connection = {
                "indices": [j0, j0+1],
                "wire_pairs": new_wire_pairs
            }

            ext_rule["connections"].append(connection)

            # ...................................
            # Connection between tiles N-1 and N. Just re-map left wires
            i0 = N - 2
            j0 = M - 2
            new_wire_pairs = []
            for pair in self._get_wires_between_tiles([1, 0], [pattern[i0], pattern[i0+1]]):
                wire = self.fwd_tile_wire_map[pair[0]]  # Map to new name
                wire = wire.replace("X1Y0", "SITE")     # X1Y0 goes to site of the tile
                wire = wire.replace("X0Y0", "PASS")     # X0Y0 goes through the tile
                new_wire_pairs.append([wire, pair[1]])

            connection = {
                "indices": [j0, j0+1],
                "wire_pairs": new_wire_pairs
            }

            ext_rule["connections"].append(connection)

            # ...................................
            # For patterns with length of 4 add a rule that spans two middle
            # SLICEs. This will correspond to passthrough wires that spans
            # across the whole row.
            if len(pattern) == 4:

                i0 = N // 2 - 1
                j0 = M // 2 - 1
                new_wire_pairs = []
                for pair in self._get_wires_between_tiles([1, 0], [pattern[i0], pattern[i0+1]]):
                    left_wire  = self.fwd_tile_wire_map[pair[0]]
                    right_wire = self.fwd_tile_wire_map[pair[1]]

                    # These wires should not be site-related !
                    assert ("X0Y0" not in left_wire)
                    assert ("X1Y0" not in left_wire)
                    assert ("X0Y0" not in right_wire)
                    assert ("X1Y0" not in right_wire)

                    new_wire_pairs.append([left_wire, right_wire])

                connection = {
                    "indices": [j0, j0+1],
                    "wire_pairs": new_wire_pairs
                }

                ext_rule["connections"].append(connection)

            # ...................................
            # Append
            self.ext_connections.append(ext_rule)

    def _purge_connections(self):
        """
        Removes connection rules that refer to "old" tile types.

        :return:
        """

        rules_to_remove = set()

        # Loop over all old tile types.
        for old_tile_type in self.tile_types:

            # Loop over all connection rules that mention old types
            for rule in self.connections:
                if rule.tile_types[0] == old_tile_type or rule.tile_types[1] == old_tile_type:
                    rules_to_remove.add(rule)
                    logging.warning("Removing: " + rule.str_no_wires())

        # Remove the rules
        self.connections -= rules_to_remove

    def split(self):

        # Identify tile co-location patterns
        self.old_conn_patterns = self._identify_tile_patterns()

        # Process connection patterns
        self.new_conn_patterns = self._process_tile_patterns()

        # Purge connections related to splitted tile types
        self._purge_connections()

        # Join old and new
        self.connections |= self.new_connections

        # Append hard coded rules
        self.connections |= set([Rule.from_dict(c) for c in self.hard_coded_rules])

        # Save tile connection rules to tileconn.json
        connections = [c.__dict__() for c in self.connections]

        file_name = os.path.join(self.db_overlay, "tileconn.json")
        logging.info("Writing '%s'" % file_name)

        with open(file_name, "w") as fp:
            json.dump(connections,  fp, sort_keys=True, indent=1)

        # Save extended connection rules to tileconn_ext.json
        file_name = os.path.join(self.db_overlay, "tileconn_ext.json")
        logging.info("Writing '%s'" % file_name)

        with open(file_name, "w") as fp:
            json.dump(self.ext_connections,  fp, sort_keys=True, indent=1)

# =============================================================================


def main():
    """
    The main.

    :return:
    """

    # Parse arguments
    parser = argparse.ArgumentParser()
    parser.add_argument("--db_root", required=True, type=str, help="Database root (input files)")
    parser.add_argument("--db_overlay", type=str, default=".", help="Database overlay root (for output files)")
    parser.add_argument("--split-tiles", required=True, type=str, nargs="*", action="append", help="Tile types to split")

    args = parser.parse_args()

    # Logging
    logging.basicConfig(level=logging.DEBUG, format="%(message)s")

    # Build a list of tile types to split
    tile_types = set()
    for types in args.split_tiles:
        tile_types |= set(types)
    tile_types = list(tile_types)

    # Create and initialize connection
    splitter = ConnSplitter(args.db_root, args.db_overlay, tile_types)

    # Do the split
    splitter.split()

# =============================================================================


if __name__ == "__main__":
    main()


#         self.tile_type_defs = {}
#
#         self.bwd_tile_type_map = {} # FIXME: These are set externally for now. Content taken from GridSplitter
#         self.fwd_tile_type_map = {}
#
#         self.new_connections = set()
#
#         # Input tileconn.json
#         tileconn_file = os.path.join(db_root, "tileconn.json")
#         if not os.path.isfile(tileconn_file):
#             raise RuntimeError("Tile connection file '%s' not found!" % tileconn_file)
#         self.tileconn_file = tileconn_file
#
#         # Load connections
#         self._load_tileconn()
#
#     def _load_tileconn(self):
#         """
#         Loads tileconn.json and converts connection representation to internal format.
#
#         :return:
#         """
#
#         # Load the tileconn file
#         with open(self.tileconn_file, "r") as fp:
#             rules = json.load(fp)
#             self.old_connections = set([Rule.from_dict(c) for c in rules])
#
#     def _load_tile_type(self, tile_type):
#         """
#         Loads tile type definition of a particular tile
#
#         :param tile_type:
#         :return:
#         """
#
#         file_name = os.path.join(self.db_root, "tile_type_%s.json" % tile_type)
#         with open(file_name, "r") as fp:
#             self.tile_type_defs[tile_type] = json.load(fp)
#
#     def _get_tile_site_wires(self, tile_type):
#         """
#         Returns a list of wires that comes out of a tile which are relevant for
#         each site in it.
#
#         :param tile_type:
#         :return:
#         """
#
#         # Load tile type
#         file_name = os.path.join(self.db_root, "tile_type_%s.json" % tile_type)
#         with open(file_name, "r") as fp:
#             tile_type_def = json.load(fp)
#
#         # Find wires relevant to sites
#         tile_wires = set(tile_type_def["wires"])
#         site_wires = {}
#
#         #logging.debug("Tile type: '%s'" % tile_type)
#
#         for site in tile_type_def["sites"]:
#
#             # Get site name and pins
#             name  = site["type"] + "_" + site["name"]
#             wires = set(site["site_pins"].values())
#
#             #logging.debug(" site name: '%s'" % name)
#
#             relevant_wires = set()
#
#             for wire in wires:
#
#                 # A driect connection from site to tile pin
#                 if wire in tile_wires:
#                     relevant_wires.add(wire)
#                     #logging.debug("  - %s" % wire)
#
#                 # Check if the wire goes through a pip
#                 for pip in tile_type_def["pips"].values():
#
#                     if pip["src_wire"] == wire and pip["dst_wire"] in tile_wires:
#                         relevant_wires.add(pip["dst_wire"])
#                         #logging.debug("  + %s" % pip["dst_wire"])
#
#                     if pip["dst_wire"] == wire and pip["src_wire"] in tile_wires:
#                         relevant_wires.add(pip["src_wire"])
#                         #logging.debug("  + %s" % pip["src_wire"])
#
#             # Store
#             site_wires[name] = relevant_wires
#
#         return site_wires
#
#     def _make_connections_between_splitted_tile_types(self):
#         """
#         Self explanatory.
#
#         :return:
#         """
#
#         logging.info("Making connections between splitted tile types...")
#
#         # Loop over all old tile types.
#         old_tile_types = list(self.fwd_tile_type_map.keys())
#         for old_tile_type in old_tile_types:
#
#             # Loop over connection rules, collect all wires related to an old tile type
#             all_wires = set()
#             for rule in self.old_connections:
#
#                 # Only horizontal
#                 if rule.grid_deltas[1] != 0:
#                     continue
#
#                 # The rule does not mention old tile type
#                 if rule.tile_types[0] != old_tile_type and rule.tile_types[1] != old_tile_type:
#                     continue
#
#                 # Extract wires
#                 if rule.tile_types[0] == old_tile_type:
#                     all_wires |= set([pair[0] for pair in rule.wire_pairs])
#                 if rule.tile_types[1] == old_tile_type:
#                     all_wires |= set([pair[1] for pair in rule.wire_pairs])
#
#             # Make new rules that connects the tile type that was split.
#             rule = Rule(
#                 [1, 0],
#                 list(self.fwd_tile_type_map[old_tile_type]),
#                 [[wire, wire] for wire in all_wires]
#             )
#
#             print(rule.str_no_wires())
#             self.new_connections.add(rule)
#
#     def _make_connections_between_new_tile_types(self):
#         """
#         Self explanatory.
#
#         :return:
#         """
#
#         rules = set()
#
#         logging.info("Making connections between new tile types...")
#
#         # Determine which wires are relevant for a particular site
#         tile_site_wires = {}
#         for old_tile_type in self.fwd_tile_type_map.keys():
#             tile_site_wires[old_tile_type] = self._get_tile_site_wires(old_tile_type)
#             #logging.debug(old_tile_type + " " + str(list(tile_site_wires[old_tile_type].keys())))
#
#         # Change data structure
#         tile_wires = {}
#         for tile_name, site_wires in tile_site_wires.items():
#             for site_name in site_wires.keys():
#                 new_tile_name = tile_name + "_" + site_name
#                 tile_wires[new_tile_name] = site_wires[site_name]
#                 #logging.debug(new_tile_name)
#
#         # Loop over all old tile types.
#         for old_tile_type_a in self.fwd_tile_type_map.keys():
#             for old_tile_type_b in self.fwd_tile_type_map.keys():
#
#                 # Loop over all connection rules that are between old tile types
#                 for rule in self.old_connections:
#                     if rule.tile_types[0] == old_tile_type_a and rule.tile_types[1] == old_tile_type_b:
#                         rules.add(rule)
#                     if rule.tile_types[0] == old_tile_type_b and rule.tile_types[1] == old_tile_type_a:
#                         rules.add(rule)
#
#         # Process the rules
#         new_rules = set()
#         for rule in rules:
#
#             # Vertical
#             if rule.grid_deltas[0] == 0:
#
#                 assert(abs(rule.grid_deltas[1]) == 1)
#
#                 # For each sub-tile
#                 for i in [0, 1]:
#                     new_rule = rule.copy()
#                     #logging.debug(new_rule.str_no_wires())
#
#                     # Change tile types
#                     new_rule.tile_types = [
#                         self.fwd_tile_type_map[rule.tile_types[0]][i],
#                         self.fwd_tile_type_map[rule.tile_types[1]][i],
#                     ]
#
#                     # Remove unnecessary wires
#                     new_wire_pairs = []
#                     wires_to_keep  = set(tile_wires[new_rule.tile_types[0]]) | set(tile_wires[new_rule.tile_types[1]])
#                     for pair in new_rule.wire_pairs:
#                         if pair[0] in wires_to_keep or pair[1] in wires_to_keep:
#                             new_wire_pairs.append(pair)
#
#                     assert(len(new_wire_pairs) != 0)
#                     new_rule.wire_pairs = new_wire_pairs
#
#                     #logging.debug(" " + new_rule.str_no_wires())
#                     new_rules.add(new_rule)
#
#             # Horizontal or diagonal
#             else:
#                 new_rule = rule.copy()
#
#                 #logging.debug(new_rule.str_no_wires())
#
#                 if rule.grid_deltas[0] > 0:
#                     left_tile  = self.fwd_tile_type_map[rule.tile_types[0]][1]
#                     right_tile = self.fwd_tile_type_map[rule.tile_types[1]][0]
#                     new_rule.tile_types = [left_tile, right_tile]
#                     logging.debug(rule.str_no_wires() + " -> " + new_rule.str_no_wires())
#
#                 if rule.grid_deltas[0] < 0:
#                     left_tile  = self.fwd_tile_type_map[rule.tile_types[1]][1]
#                     right_tile = self.fwd_tile_type_map[rule.tile_types[0]][0]
#                     new_rule.tile_types = [right_tile, left_tile]
#                     logging.debug(rule.str_no_wires() + " -> " + new_rule.str_no_wires())
#
#                 #logging.debug(" " + new_rule.str_no_wires())
#                 new_rules.add(new_rule)
#                 #print(" ", new_rule.grid_deltas, new_rule.tile_types)
#
#         # Merge new connections
#         self.new_connections |= new_rules
#
#     def _make_connections_between_new_and_old_tile_types(self):
#         """
#         Self explanatory.
#
#         :return:
#         """
#
#         rules = set()
#
#         logging.info("Making connections between new and old tile types...")
#
#         # Determine which wires are relevant for a particular site
#         tile_site_wires = {}
#         for old_tile_type in self.fwd_tile_type_map.keys():
#             tile_site_wires[old_tile_type] = self._get_tile_site_wires(old_tile_type)
#
#         # Change data structure
#         tile_wires = {}
#         for tile_name, site_wires in tile_site_wires.items():
#             for site_name in site_wires.keys():
#                 new_tile_name = tile_name + "_" + site_name
#                 tile_wires[new_tile_name] = site_wires[site_name]
#
#         # Loop over all old tile types.
#         old_tile_types = list(self.fwd_tile_type_map.keys())
#         for old_tile_type in old_tile_types:
#
#             # Loop over all connection rules that mention old types
#             for rule in self.old_connections:
#                 if rule.tile_types[0] == old_tile_type or rule.tile_types[1] == old_tile_type:
#                     rules.add(rule)
#
#         # Process the rules
#         new_rules = set()
#         for rule in rules:
#
#             # Vertical
#             if rule.grid_deltas[0] == 0:
#                 assert(abs(rule.grid_deltas[1]) == 1)
#
#                 logging.info(str(rule) + " ->")
#
#                 # For each sub-tile
#                 for i in [0, 1]:
#                     new_rule = rule.copy()
#
#                     wires_to_keep = set()
#
#                     # Change tile types, collect wires to keep
#                     if rule.tile_types[0] in old_tile_types:
#                         new_rule.tile_types[0] = self.fwd_tile_type_map[rule.tile_types[0]][i]
#                         wires_to_keep |= set(tile_wires[new_rule.tile_types[0]])
#
#                     if rule.tile_types[1] in old_tile_types:
#                         new_rule.tile_types[1] = self.fwd_tile_type_map[rule.tile_types[1]][i]
#                         wires_to_keep |= set(tile_wires[new_rule.tile_types[1]])
#
#                     # Remove unnecessary wires
#                     new_wire_pairs = []
#                     for pair in new_rule.wire_pairs:
#                         if pair[0] in wires_to_keep or pair[1] in wires_to_keep:
#                             new_wire_pairs.append(pair)
#
#                     assert(len(new_wire_pairs) != 0)
#                     new_rule.wire_pairs = new_wire_pairs
#
#                     new_rules.add(new_rule)
#                     logging.info(" " + str(new_rule))
#
#             # Horizontal or diagonal
#             else:
#                 #logging.debug(rule.str_no_wires())
#
#                 new_rule = None
#
#                 if rule.grid_deltas[0] < 0:
#                     new_rule = rule.copy()
#
#                     if rule.tile_types[0] in old_tile_types:
#                         new_tile_type = self.fwd_tile_type_map[rule.tile_types[0]][0]  # Left
#                         new_rule.tile_types[0] = new_tile_type
#
#                     if rule.tile_types[1] in old_tile_types:
#                         new_tile_type = self.fwd_tile_type_map[rule.tile_types[1]][1]  # Right
#                         new_rule.tile_types[1] = new_tile_type
#
#                 if rule.grid_deltas[0] > 0:
#                     new_rule = rule.copy()
#
#                     if rule.tile_types[1] in old_tile_types:
#                         new_tile_type = self.fwd_tile_type_map[rule.tile_types[1]][0]  # Left
#                         new_rule.tile_types[1] = new_tile_type
#
#                     if rule.tile_types[0] in old_tile_types:
#                         new_tile_type = self.fwd_tile_type_map[rule.tile_types[0]][1]  # Right
#                         new_rule.tile_types[0] = new_tile_type
#
#                 if new_rule is not None:
#                     logging.debug(rule.str_no_wires() + " -> " + new_rule.str_no_wires())
#                     new_rules.add(new_rule)
#                     #logging.debug(" " + new_rule.str_no_wires())
#
#         # Merge new connections
#         self.new_connections |= new_rules
#
#     def _purge_connections(self):
#         """
#         Removes connection rules that refer to "OLD" tile types.
#
#         :return:
#         """
#
#         rules_to_remove = set()
#
#         # Loop over all old tile types.
#         old_tile_types = list(self.fwd_tile_type_map.keys())
#         for old_tile_type in old_tile_types:
#
#             # Loop over all connection rules that mention old types
#             for rule in self.new_connections:
#                 if rule.tile_types[0] == old_tile_type or rule.tile_types[1] == old_tile_type:
#                     rules_to_remove.add(rule)
#                     logging.warning("Removing: " + rule.str_no_wires())
#
#         # Remove the rules
#         self.new_connections -= rules_to_remove
#
#     def split(self):
#         """
#         Triggers the split.
#
#         :return:
#         """
#
#         self._make_connections_between_splitted_tile_types()
#         self._make_connections_between_new_tile_types()
#         self._make_connections_between_new_and_old_tile_types()
#
# #        # Loop over all old tile types.
# #        old_tile_types = list(self.fwd_tile_type_map.keys())
# #        for old_tile_type in old_tile_types:
#
# #            for rule in self.new_connections:
# #                if rule.tile_types[0] == old_tile_type or rule.tile_types[1] == old_tile_type:
# #                    print("ERROR: " + rule.str_no_wires())
#
#         for rule in self.new_connections:
#             logging.debug("Adding  : " + rule.str_no_wires())
#
#         self.new_connections |= self.old_connections
#
#         self._purge_connections()
#
#         # Save tile connections
#         connections = [c.__dict__() for c in self.new_connections]
#
#         file_name = os.path.join(self.db_overlay, "tileconn.json")
#         logging.info("Writing '%s'" % file_name)
#
#         with open(file_name, "w") as fp:
#             json.dump(connections,  fp, sort_keys=True, indent=1)
#             fp.flush()
#
