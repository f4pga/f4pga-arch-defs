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

    def __init__(self, db_root, db_overlay, tile_type):
        """
        Constructor.

        :param db_root: Prjxray database root (input folder)
        :param db_overlay: Prjxray database overlay root (output folder)
        """

        self.db_root = db_root
        self.db_overlay = db_overlay

        # Load tile info
        tile_type_file = os.path.join(db_root, "tile_type_%s.json" % tile_type)
        if not os.path.isfile(tile_type_file):
            raise RuntimeError("Tile type '%s' not found in DB" % tile_type)

        with open(tile_type_file, "r") as fp:
            self.tile = json.load(fp)

    def _extract_site(self, site_of_interest):
        """
        Extracts a site from a tile type. Generates a new tile type.

        :param site_of_interest:
        :return:
        """

        # Copy the tile
        new_tile = deepcopy(self.tile)

        # Build a list of site and non-site wires
        site_wires = []
        non_site_wires = []

        for site in self.tile["sites"]:
            if site != site_of_interest:
                non_site_wires.extend([wire for wire in site["site_pins"].values()])
            else:
                site_wires.extend([wire for wire in site["site_pins"].values()])

        # Do not remove wires that are not relevant to a particular site. These will serve
        # as a pass-through path.

        # # Remove the wires
        # for wire in non_site_wires:
        #     new_tile["wires"].remove(wire)

        # Remove pips
        for pip_name, pip in self.tile["pips"].items():

            # We have a pip that connects two wires from different sites.
            # The tile cannot be split
            if (pip["src_wire"] in non_site_wires and pip["dst_wire"] in site_wires) or \
               (pip["dst_wire"] in non_site_wires and pip["src_wire"] in site_wires):
                raise RuntimeError("Pip '%s' spans accross sites!" % pip_name)

            # Delete
            if pip["src_wire"] in non_site_wires or pip["dst_wire"] in non_site_wires:
                del new_tile["pips"][pip_name]

        # Remove sites of non-interest
        for site in self.tile["sites"]:
            if site != site_of_interest:
                new_tile["sites"].remove(site)

        # Set new tile type of the new tile  # FIXME: Check if the naming is correct !
        new_tile["tile_type"] += "_" + site_of_interest["type"] + "_" + site_of_interest["name"]

        return new_tile

    def split(self):
        """
        Triggers the split.

        :return:
        """

        # Loop over all sites of the tile
        for site in self.tile["sites"]:

            # Extract
            new_tile = self._extract_site(site)

            # Save to JSON
            json_name = "tile_type_%s.json" % new_tile["tile_type"]
            file_name = os.path.join(self.db_overlay, json_name)
            with open(file_name, "w") as fp:
                json.dump(new_tile, fp, sort_keys=True, indent=1)

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
    parser.add_argument("--tile", required=True, type=str, help="Tile type to split")

    args = parser.parse_args()

    # Logging
    logging.basicConfig(level=logging.DEBUG, format="%(message)s")

    # Create and initialize grid splitter
    splitter = TileSplitter(args.db_root, args.db_overlay, args.tile)

    # Do the split
    splitter.split()

# =============================================================================


if __name__ == "__main__":
    main()
