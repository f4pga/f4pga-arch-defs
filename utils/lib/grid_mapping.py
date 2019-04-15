#!/usr/bin/env python3
import sqlite3
import argparse
import os
import itertools

# =============================================================================


class GridLocMap(object):
    """
    This class preforms forward (physical -> VPR) and backward (VPR -> physical)
    grid location mapping.
    """

    def __init__(self, fwd_loc_map, bwd_loc_map):
        self.fwd_loc_map = fwd_loc_map
        self.bwd_loc_map = bwd_loc_map

    @staticmethod
    def generate_one_to_one_map(extent):
        """
        Generates a one-to-one map for specified location range.

        Args:
            extent: A 4-element tuple with the grid extent:
                xmin, ymin, xmax, ymax

        Returns:
            A GridLocMap object with the grid mapping.
        """

        xmin, ymin, xmax, ymax = extent

        fwd_loc_map = {}
        bwd_loc_map = {}

        # Make a one-to-one map
        for x, y in itertools.product(range(xmin, xmax + 1), range(ymin,
                                                                   ymax + 1)):

            fwd_loc_map[(x, y)] = [(x, y)]
            bwd_loc_map[(x, y)] = [(x, y)]

        # Return map object
        return GridLocMap(fwd_loc_map, bwd_loc_map)

    @staticmethod
    def generate_shift_map(extent, shift_x, shift_y):
        """
        Generates a one-to-one map for specified location range. For debugging
        purposes.

        Args:
            extent: A 4-element tuple with the grid extent:
                xmin, ymin, xmax, ymax
            shift_x: Grid shift in X axis
            shift_y: Grid shift in Y axis

        Returns:
            A GridLocMap object with the grid mapping.
        """

        xmin, ymin, xmax, ymax = extent

        fwd_loc_map = {}
        bwd_loc_map = {}

        # Make a one-to-one map
        for x, y in itertools.product(range(xmin, xmax + 1), range(ymin,
                                                                   ymax + 1)):

            phy_loc = (x, y)
            vpr_loc = (x + shift_x, y + shift_y)

            fwd_loc_map[phy_loc] = [vpr_loc]
            bwd_loc_map[vpr_loc] = [phy_loc]

        # Return map object
        return GridLocMap(fwd_loc_map, bwd_loc_map)

    @staticmethod
    def load_from_database(conn):
        """
        Loads grid location mapping from a SQL database. Returns a GridLocMap
        object.

        Args:
            conn: A database connection object

        Returns:
            A GridLocMap object with the grid mapping.
        """

        c = conn.cursor()

        # Query the grid map from the database
        grid_loc_map = c.execute(
            """
SELECT phy.grid_x, phy.grid_y, vpr.grid_x, vpr.grid_y
FROM phy_tile phy
INNER JOIN grid_loc_map map
ON phy.pkey = map.phy_tile_pkey
INNER JOIN tile vpr
ON vpr.pkey = map.vpr_tile_pkey
"""
        )

        # Build maps
        fwd_loc_map = {}
        bwd_loc_map = {}

        for loc_pair in grid_loc_map:
            phy_loc = loc_pair[0:2]
            vpr_loc = loc_pair[2:4]

            if phy_loc not in fwd_loc_map.keys():
                fwd_loc_map[phy_loc] = []
            fwd_loc_map[phy_loc].append(vpr_loc)

            if vpr_loc not in bwd_loc_map.keys():
                bwd_loc_map[vpr_loc] = []
            bwd_loc_map[vpr_loc].append(phy_loc)

        # Return map object
        return GridLocMap(fwd_loc_map, bwd_loc_map)

    def get_vpr_loc(self, grid_loc):
        return self.fwd_loc_map[grid_loc]

    def get_phy_loc(self, grid_loc):
        return self.bwd_loc_map[grid_loc]


# =============================================================================


def get_phy_grid_extent(conn):
    """
    Returns a tuple with (xmin, ymin, xmax, ymax) which defines
    the grid extent.
    """

    # Get coordinates of all tiles
    cursor = conn.cursor()
    coords = list(cursor.execute("SELECT grid_x, grid_y FROM phy_tile"))

    # Determine extent
    xmin = min([loc[0] for loc in coords])
    xmax = max([loc[0] for loc in coords])
    ymin = min([loc[1] for loc in coords])
    ymax = max([loc[1] for loc in coords])

    return xmin, ymin, xmax, ymax


def get_vpr_grid_extent(conn):
    """
    Returns a tuple with (xmin, ymin, xmax, ymax) which defines
    the grid extent.
    """

    # Get coordinates of all tiles
    cursor = conn.cursor()
    coords = list(cursor.execute("SELECT grid_x, grid_y FROM tile"))

    # Determine extent
    xmin = min([loc[0] for loc in coords])
    xmax = max([loc[0] for loc in coords])
    ymin = min([loc[1] for loc in coords])
    ymax = max([loc[1] for loc in coords])

    return xmin, ymin, xmax, ymax


# =============================================================================

if __name__ == "__main__":
    main()
