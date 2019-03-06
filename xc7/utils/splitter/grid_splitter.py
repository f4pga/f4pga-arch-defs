#!/usr/bin/env python3
from collections import namedtuple
from copy import deepcopy

import os
import argparse
import logging

import json

# =============================================================================


class GridSplitter(object):
    """
    Tile grid splitter class.

    This class operates on tile grid loaded from the tilegrid.json as well as
    on tile type definition json files.

    The purpose is to split columns in half that contain particular tile types
    as well as those tiles themselves. For each split tile type its sites are
    extracted and converted to new top-level tile types.

    The class also generates a forward and backward tile type map for later use.
    """

    Loc = namedtuple("Loc", "x y")

    def __init__(self, db_root, db_overlay):
        """
        Constructor.

        :param db_root: Prjxray database root (input folder)
        :param db_overlay: Prjxray database overlay root (output folder)
        """

        self.db_root = db_root
        self.db_overlay = db_overlay

        self.tile_types_to_split = set()
        self.tile_type_defs = {}

        self.split_columns = set()

        self.old_grid_by_tile = None
        self.new_grid_by_tile = None

        self.bwd_tile_name_map = {}
        self.bwd_tile_type_map = {}

        self.fwd_tile_name_map = {}
        self.fwd_tile_type_map = {}

        self.new_tile_types = set()

        # Input tilegrid.json
        tilegird_file = os.path.join(db_root, "tilegrid.json")
        if not os.path.isfile(tilegird_file):
            raise RuntimeError("Tile grid file '%s' not found!" % tilegird_file)
        self.tilegrid_file = tilegird_file

        # Load the grid
        self._load_tilegrid()

    def _load_tilegrid(self):
        """
        Loads the tilegrid.json file

        :return:
        """

        # Load the tilegrid file
        with open(self.tilegrid_file, "r") as fp:
            self.old_grid_by_tile = json.load(fp)

    def _load_tile_type(self, tile_type):
        """
        Loads tile type definition of a particular tile and places them in
        a dictionary for later use.

        :param tile_type:
        :return:
        """

        file_name = os.path.join(self.db_root, "tile_type_%s.json" % tile_type)
        with open(file_name, "r") as fp:
            self.tile_type_defs[tile_type] = json.load(fp)

    def _split_tile_of_interest(self, tile_name, tile, ofs):
        """
        Splits a tile of interest into two tiles. Each of them will have only one site

        :param tile_name:
        :param tile:
        :param ofs:
        :return:
        """

        tile_type  = tile["type"]
        tile_loc   = self.Loc(tile["grid_x"], tile["grid_y"])
        tile_sites = sorted(list(tile["sites"].keys()))

        new_tiles  = {}

        # Generate new tiles and a tile map
        for i, new_tile_type in enumerate(self.fwd_tile_type_map[tile_type]):

            # TODO: Match real slice XY with site XY !!!!!!!!
            new_tile_name = tile_sites[i]

            # Generate a new tile
            new_tile = {
                "grid_x": tile_loc.x + ofs + i,
                "grid_y": tile_loc.y,
                "sites" : {new_tile_name: tile["sites"][new_tile_name]},  # TODO: Site name is equal to tile name
                "type"  : new_tile_type
            }

            new_tiles[new_tile_name] = new_tile

        return new_tiles

    def _split_tile_of_non_interest(self, tile_name, tile, ofs):
        """
        Splits a tile of non-interest into two identical.

        :param tile_name:
        :param tile:
        :param ofs:
        :return:
        """

        new_tiles = {}

        # Add two identical tiles with different suffixes
        for i, suffix in enumerate(["_L", "_R"]):
            new_tile_name = tile_name + suffix
            new_tile      = deepcopy(tile)

            new_tile["grid_x"] += ofs + i
            new_tiles[new_tile_name] = new_tile

        return new_tiles

    def _split_grid(self, columns):
        """
        Performs the grid split

        :param columns:
        :return:
        """

        self.new_grid_by_tile = {}

        # Loop over the whole grid
        logging.info("Splitting grid...")
        for tile_name, tile in self.old_grid_by_tile.items():
            tile_loc = self.Loc(tile["grid_x"], tile["grid_y"])

            ofs = sum([x < tile_loc.x for x in columns])

            # Split this tile
            if tile_loc.x in columns:
                tile_type = tile["type"]

                # Split a tile of interest
                if tile_type in self.tile_types_to_split:
                    new_tiles = self._split_tile_of_interest(tile_name, tile, ofs)
                    self.new_grid_by_tile.update(new_tiles)

                # Split a tile of non-interest
                else:
                    new_tiles = self._split_tile_of_non_interest(tile_name, tile, ofs)
                    self.new_grid_by_tile.update(new_tiles)

            # Do not split, copy and re-assign coordinates if necessary
            else:

                tile["grid_x"] += ofs
                self.new_grid_by_tile[tile_name] = tile

    def add_tile_type_to_split(self, tile_type):
        """
        Adds a tile type to be splitted. Determines which columns need to be split

        :param tile_type:
        :return:
        """

        # Already have this one
        if tile_type in self.tile_types_to_split:
            return

        # Load the tile type definition
        self._load_tile_type(tile_type)

        # Append
        self.tile_types_to_split.add(tile_type)

        # Find columns to split
        logging.info("Splitting columns containing '%s'" % tile_type)

        for tile_name, tile in self.old_grid_by_tile.items():
            if tile["type"] == tile_type:
                self.split_columns.add(tile["grid_x"])

    def _build_tile_type_maps(self):
        """
        Builds a forward and backward map of tile types. Also generates a set of new tile types

        :return:
        """

        # Loop over all tile types to split
        for tile_type in self.tile_types_to_split:
            tile_type_def = self.tile_type_defs[tile_type]

            # Loop over all tile sites
            sites_by_loc = {}

            for site in tile_type_def["sites"]:
                new_tile_type = tile_type + "_" + site["type"] + "_" + site["name"]
                new_tile_ofs  = self.Loc(site["x_coord"], site["y_coord"])

                # Append to site offset map
                sites_by_loc[new_tile_ofs] = new_tile_type
                # Append to backward map
                self.bwd_tile_type_map[new_tile_type] = tile_type

            # Sort locations
            sorted_keys = sorted(sites_by_loc.keys(), key=lambda ofs: ofs.x + 1000*ofs.y)  # FIXME: Will crash for grid with width > 1000

            # Append to forward map
            self.fwd_tile_type_map[tile_type] = [sites_by_loc[key] for key in sorted_keys]

        # Make new tile type set
        self.new_tile_types = set(self.bwd_tile_type_map.keys())

        # Dump maps
        logging.debug("fwd_tile_type_map:")
        for type, new_type in self.fwd_tile_type_map.items():
            logging.debug(" " + str(type) + " -> " + str(new_type))

        logging.debug("bwd_tile_type_map:")
        for new_type, type in self.bwd_tile_type_map.items():
            logging.debug(" " + str(new_type) + " -> " + str(type))

    def split(self):
        """
        Triggers the split operation.

        :return:
        """

        # Build a map of tile types to split
        self._build_tile_type_maps()

        # Split the grid
        columns = sorted(list(self.split_columns))
        self._split_grid(columns)

        # Save the new tile grid
        file_name = os.path.join(self.db_overlay, "tilegrid.json")
        logging.info("Writing '%s'" % file_name)

        with open(file_name, "w") as fp:
            json.dump(self.new_grid_by_tile, fp, sort_keys=True, indent=1)
            fp.flush()

# =============================================================================


def main():
    """
    The main

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

    # .................................

    # Create and initialize grid splitter
    grid_splitter = GridSplitter(args.db_root, args.db_overlay)

    # Add tile types to split
    for tile_type_list in args.split_tiles:
        for tile_type in tile_type_list:
            grid_splitter.add_tile_type_to_split(tile_type)

    # Do the split
    grid_splitter.split()

    # .................................

    # Initialize connection rule splitter
    # FIXME: Now it is a hackish way...
    from conn_splitter import ConnSplitter
    conn_splitter = ConnSplitter(args.db_root, args.db_overlay)

    conn_splitter.bwd_tile_type_map = grid_splitter.bwd_tile_type_map
    conn_splitter.fwd_tile_type_map = grid_splitter.fwd_tile_type_map

    # Split connection rules
    conn_splitter.split()

    # .................................

    # Split tile type definitions
    from tile_splitter import TileSplitter

    for tile_type_list in args.split_tiles:
        for tile_type in tile_type_list:
            splitter = TileSplitter(args.db_root, args.db_overlay, tile_type)
            splitter.split()

# =============================================================================


if __name__ == "__main__":
    main()
