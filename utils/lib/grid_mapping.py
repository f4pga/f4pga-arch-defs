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

    def __init__(self, db_conn):

        # Create a database cursor
        self.db_cursor = db_conn.cursor()

        # Get the whole table
        grid_loc_map = self.db_cursor.execute(
            "SELECT grid_phy_x, grid_phy_y, grid_vpr_x, grid_vpr_y FROM grid_loc_map"
        ).fetchall()

        # Build maps
        self.fwd_loc_map = {}
        self.bwd_loc_map = {}

        for loc_pair in grid_loc_map:
            phy_loc = loc_pair[0:2]
            vpr_loc = loc_pair[2:4]

            if phy_loc not in self.fwd_loc_map.keys():
                self.fwd_loc_map[phy_loc] = []
            self.fwd_loc_map[phy_loc].append(vpr_loc)

            if vpr_loc not in self.bwd_loc_map.keys():
                self.bwd_loc_map[vpr_loc] = []
            self.bwd_loc_map[vpr_loc].append(phy_loc)

    def get_vpr_loc(self, grid_loc):
        return tuple(self.fwd_loc_map[grid_loc])

    def get_phy_loc(self, grid_loc):
        return tuple(self.bwd_loc_map[grid_loc])

# =============================================================================

def create_tables(conn):
    """
    Creates database tables related to grid location mappings
    """

    sql_file = os.path.join(os.path.dirname(__file__), "grid_mapping.sql")

    with open(sql_file, "r") as fp:
        cursor = conn.cursor()
        cursor.executescript(fp.read())
        conn.commit()

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

    return (xmin, ymin, xmax, ymax)

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

    return (xmin, ymin, xmax, ymax)

def initialize_one_to_one_map(conn):
    """
    Initializes a one to one mapping of grid coordinates. The grid must be
    imported to the database before calling this function.
    """

    cursor = conn.cursor()

    # Clear the table (just in case)
    cursor.executescript("DELETE FROM grid_loc_map; VACUUM;")

    # Get the physical grid extent
    extent = get_phy_grid_extent(conn)

    # Make a one-to-one map
    for x, y in itertools.product(range(extent[0], extent[2]+1), range(extent[1], extent[3]+1)):
        cursor.execute("INSERT INTO grid_loc_map VALUES (?, ?, ?, ?);", (x, y, x, y))

    cursor.execute("COMMIT TRANSACTION;")
    cursor.connection.commit()

# =============================================================================

def main():
    """
    When executed adds grid location map table(s) to the database and initializes
    a "dummy" one-to-one map.
    """

    # Parse arguments
    parser = argparse.ArgumentParser()
    parser.add_argument("--db", type=str, required=True, help="Database file")

    args = parser.parse_args()

    # Open the DB
    conn = sqlite3.Connection(args.db)

    # Create table
    create_tables(conn)

    # Initialize one-to-one mapping
    initialize_one_to_one_map(conn)

    conn.close()

# =============================================================================

if __name__ == "__main__":
    main()

