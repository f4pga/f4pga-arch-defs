#!/usr/bin/env python3
from copy import deepcopy

import os
import argparse
import logging

import json

# =============================================================================


class TileSplitter(object):
    """
    The tile splitter class allows to split tile type definition into individual
    single-site tiles.

    The class reads the tile type definition from a JSON file and generates new
    tile types, one for each site. Each of new tile types contain only a single
    site of a given type.
    """

    def __init__(self, db_root, db_overlay, tile_types):
        """
        Constructor.

        :param db_root: Prjxray database root (input folder)
        :param db_overlay: Prjxray database overlay root (output folder)
        """

        self.db_root = db_root
        self.db_overlay = db_overlay

        self.wire_name_map = {}

        # Load tile info
        self.tiles = {}

        for tile_type in tile_types:

            tile_type_file = os.path.join(db_root, "tile_type_%s.json" % tile_type)
            if not os.path.isfile(tile_type_file):
                raise RuntimeError("Tile type '%s' not found in DB" % tile_type)

            with open(tile_type_file, "r") as fp:
                self.tiles[tile_type] = json.load(fp)

    def _build_site_type_list(self):
        """
        List all unique site types among specified tiles to be split

        :return:
        """

        site_types = set()

        # Build a set of unique site types
        for tile in self.tiles.values():
            for site in tile["sites"]:
                site_type = site["type"]
                site_types.add(site_type)

        logging.info("Got site types: " + str(site_types))
        return site_types

    def _build_site_pin_list(self):
        """
        Builds a list of pins relevant to each unique site type. This is
        done among all tile types given.

        :return:
        """

        site_pins = {}

        # Build a wire list for each site type
        for site_type in self.site_types:
            site_pins[site_type] = set()

            # Search for this site type in each tile
            for tile in self.tiles.values():
                for site in tile["sites"]:
                    if site["type"] == site_type:
                        pins = set(site["site_pins"].keys())
                        site_pins[site_type] |= pins

        return site_pins

    def _build_passthrough_wire_list(self):
        """
        Build a list of passthrough wires that does not connect to any site.
        :return:
        """

        passthrough_wires = set()

        # Loop over all tile types
        for tile in self.tiles.values():

            # Check each wire in tile
            for tile_wire in tile["wires"]:
                is_passthrough = True

                # Check if the wire is connected to any site directly
                for site in tile["sites"]:
                    if tile_wire in site["site_pins"].values():
                        is_passthrough = False
                        break

                # Check if the wire is connected to any pip
                for pip in tile["pips"].values():

                    if pip["src_wire"] == tile_wire:
                        is_passthrough = False
                    if pip["dst_wire"] == tile_wire:
                        is_passthrough = False
                        break

                # Got a passthrough
                if is_passthrough:

                    # Strip tile type prefix.
                    # FIXME: This is heuristic and assumes that if there is a "_" in name then right before
                    # FIXME: the "_" is the prefix.
                    new_tile_wire = tile_wire
                    if "_" in new_tile_wire:
                        new_tile_wire = new_tile_wire.split("_", 1)
                        new_tile_wire = "".join(new_tile_wire[1:])

                    # Add to the passthrough list
                    passthrough_wires.add(new_tile_wire)

                    # Add to wire name map
                    if tile_wire not in self.wire_name_map:
                        self.wire_name_map[tile_wire] = new_tile_wire

        return sorted(list(passthrough_wires))

    @staticmethod
    def _track_tile_wire_to_site_pin(tile, tile_wire):
        """
        Traces a tile wire connection from tile pin to site pin. Assumes
        up to only one pip in between !

        :param tile:
        :param tile_wire:

        :return: Site name, site pin name
        """

        # Check if the wire is connected to any site directly
        for site in tile["sites"]:
            for site_pin, site_wire in site["site_pins"].items():
                if site_wire == tile_wire:
                    return site["name"], site_pin

        # Check if the wire goes through a pip
        # FIXME: It assumes only one pip in the way !
        pip_wire = None
        for pip in tile["pips"].values():

            if pip["src_wire"] == tile_wire:
                pip_wire = pip["dst_wire"]
                break

            if pip["dst_wire"] == tile_wire:
                pip_wire = pip["src_wire"]
                break

        # Find the wire after pip in site
        for site in tile["sites"]:
            for site_pin, site_wire in site["site_pins"].items():
                if site_wire == pip_wire:
                    return site["name"], site_pin

        # Not found
        return None, None

    def _build_tile_wire_map(self):
        """
        Builds a map which allows to bind new tile wire names with old tile wire names. Wires that go to sites
        are prefixed with site name. The prefix will be removed during connection definition.
        :return:
        """

        # Loop over all tile types
        for tile in self.tiles.values():

            # Check each wire in tile
            for tile_wire in tile["wires"]:

                # Trace the wire
                site_name, site_pin = self._track_tile_wire_to_site_pin(tile, tile_wire)

                # Not connected to a site
                if site_name is None:
                    continue

                # Format wire name
                dummy_name = site_name + "_" + site_pin

                # Got a conflict in connection map
                if tile_wire in self.wire_name_map.keys():
                    if self.wire_name_map[tile_wire] != dummy_name:
                        raise RuntimeError("Conflict in tile wire map: %s -> %s, %s" % (tile_wire, self.wire_name_map[tile_wire], dummy_name))

                # Store mapping
                self.wire_name_map[tile_wire] = dummy_name

    def _build_new_tile(self, site_type):
        """
        Constructs a new tile type.

        :param site_type:
        :return:
        """

        # Build a list of all unique site pins and wires
        all_pins = set()
        for site in self.site_types:
            all_pins |= set(self.site_pins[site])

        all_pins   = sorted(list(all_pins))
        all_wires  = ["PASS_%s" % pin for pin in all_pins]

        # Build a list of this particular site pins and wires
        site_pins  = sorted(list(self.site_pins[site_type]))
        site_wires = ["SITE_%s" % pin for pin in site_pins]

        # Initialize new site type
        new_site = {
            "name": "X0Y0",
            "x_coord": 0,
            "y_coord": 0,
            "prefix": "SLICE",  # FIXME: This prefix is hard coded here !
            "type": site_type,
            "site_pins": dict(zip(site_pins, site_wires))
        }

        # Initialize new tile type
        new_tile = {
            "tile_type": site_type,
            "pips": {},
            "sites": [new_site],
            "wires": site_wires + all_wires + self.passthrough_wires
        }

        return new_tile

    def split(self):
        """
        Do the split of tiles of interest.
        :return:
        """

        # Build site type list
        self.site_types = self._build_site_type_list()

        # Collect site type pins
        self.site_pins = self._build_site_pin_list()

        # Collect passthrough wires
        self.passthrough_wires = self._build_passthrough_wire_list()

        # Build tile wire map
        self._build_tile_wire_map()

        # DEBUG

        # for s, w in self.site_wires.items():
        #     logging.debug("Site '%s' (%d):" % (s, len(w)))
        #
        #     for ww in sorted(list(w)):
        #         logging.debug(" %s" % ww)

        # logging.debug("Passthrough wires:")
        # for w in sorted(list(self.passthrough_wires)):
        #     logging.debug(" %s" % w)

        # logging.debug("Wire name map:")
        # for k in sorted(list(self.wire_name_map.keys())):
        #     logging.debug(" %s -> %s" % (k, self.wire_name_map[k]))

        # DEBUG

        # Build new tile types, save tiles
        for site_type in self.site_types:

            # Build it
            new_tile = self._build_new_tile(site_type)

            # Save to JSON
            json_name = "tile_type_%s.json" % new_tile["tile_type"]
            file_name = os.path.join(self.db_overlay, json_name)
            with open(file_name, "w") as fp:
                json.dump(new_tile, fp, sort_keys=True, indent=1)

        # Save tile wire name map
        file_name = os.path.join(self.db_overlay, "wire_name_map.json")
        with open(file_name, "w") as fp:
            json.dump(self.wire_name_map, fp, sort_keys=True, indent=1)


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

    # Create and initialize grid splitter
    splitter = TileSplitter(args.db_root, args.db_overlay, tile_types)

    # Do the split
    splitter.split()

# =============================================================================


if __name__ == "__main__":
    main()
