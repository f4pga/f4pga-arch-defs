#!/usr/bin/env python3
import logging
import itertools
import argparse
import sqlite3

import sys
sys.path.append("../")  # Hackish way...

from prjxray_db_cache import DatabaseCache
from lib.grid_mapping import get_phy_grid_extent

# =============================================================================


class GridSplitter(object):
    def __init__(self, db_conn):
        self.db_cursor = db_conn.cursor()

        self.tile_types_to_split = None

        # Get the grid from database:
        self.grid = self.db_cursor.execute(
            "SELECT grid_x, grid_y, ( SELECT name FROM tile_type WHERE tile_type.pkey = phy_tile.tile_type_pkey ) FROM phy_tile"
        )
        # Get the physical grid extent
        self.grid_extent = get_phy_grid_extent(db_conn)

    def set_tile_types_to_split(self, tile_types):
        """
        Set tile types to split
        """
        self.tile_types_to_split = tile_types

    def split(self):
        """
        Do the split
        """

        # Identify grid colums to split
        columns_to_split = set()

        for tile in self.grid:
            if tile[2] in self.tile_types_to_split:
                columns_to_split.add(tile[0])

        logging.info("Splitting columns: %s" % str(columns_to_split))

        # Clear the grid_loc_map
        self.db_cursor.executescript("DELETE FROM grid_loc_map; VACUUM;")

        # Build an new coordinate mapping
        for phy_x, phy_y in itertools.product(range(self.grid_extent[0],
                                                    self.grid_extent[2] + 1),
                                              range(self.grid_extent[1],
                                                    self.grid_extent[3] + 1)):
            vpr_x = phy_x + sum([phy_x > x for x in columns_to_split])
            vpr_y = phy_y

            self.db_cursor.execute(
                "INSERT INTO grid_loc_map VALUES (?, ?, ?, ?);",
                (phy_x, phy_y, vpr_x, vpr_y))

        # Commit
        self.db_cursor.execute("COMMIT TRANSACTION;")
        self.db_cursor.connection.commit()


# =============================================================================


def main():
    """
    The main
    """

    # Parse arguments
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--connection_database",
        required=True,
        type=str,
        help="Database of fabric connectivity")
    parser.add_argument(
        "--split-tiles",
        required=True,
        type=str,
        nargs="*",
        action="append",
        help="Tile types to split")

    args = parser.parse_args()

    # Logging
    logging.basicConfig(level=logging.DEBUG, format="%(message)s")

    # .................................

    # Build a list of tiles to split
    tile_types = []
    for tile_type_list in args.split_tiles:
        for tile_type in tile_type_list:
            tile_types.append(tile_type)

    # .................................

    with DatabaseCache(args.connection_database) as conn:

        # Initialize the grid splitter
        splitter = GridSplitter(conn)

        # Add list of tiles to split
        splitter.set_tile_types_to_split(tile_types)

        # Do the split
        splitter.split()


# =============================================================================

if __name__ == "__main__":
    main()
