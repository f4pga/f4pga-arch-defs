#!/usr/bin/env python3
import argparse
import pickle

from data_structs import *

# =============================================================================


def generate_clkmap_csv(connections, tile_grid):
    """
    Generates a map of GMUX locations for CLOCK pad locations
    """
    csv_lines = []

    # Get connection objects representing CLOCK to GMUX, extract location of
    # the cells
    for connection in connections:

        # Filter connections
        if connection.is_direct is not True:
            continue

        if "CLOCK" not in connection.src.pin or \
           "GMUX" not in connection.dst.pin:
            continue

        # Get the CLOCK tile
        if connection.src.loc not in tile_grid:
            print("ERROR: No tile for the connection endpoint", connection.src)
            continue

        tile = tile_grid[connection.src.loc]

        # Get the CLOCK cell
        for c in tile.cells:
            if c.type == "CLOCK":
                cell = c
                break
        else:
            print(
                "ERROR: No CLOCK cell in tile at {}".format(
                    connection.src.loc
                )
            )
            continue

        # Format the CSV line
        line = [
            cell.alias,
            str(connection.src.loc.x),
            str(connection.src.loc.y),
            str(connection.src.loc.z),
            str(connection.dst.loc.x),
            str(connection.dst.loc.y),
            str(connection.dst.loc.z),
        ]

        csv_lines.append(",".join(line))

    return csv_lines


# =============================================================================


def main():

    # Parse arguments
    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter
    )

    parser.add_argument(
        "--db",
        type=argparse.FileType("rb"),
        required=True,
        help="Input VPR database file of the device"
    )
    parser.add_argument(
        "-o",
        type=argparse.FileType("w"),
        default="clkmap.csv",
        help="Output CLOCK to GMUX map CSV file"
    )

    args = parser.parse_args()

    # Load data from the database
    db = pickle.load(args.db)

    connections = db["connections"]
    vpr_tile_grid = db["vpr_tile_grid"]

    # Generate the CSV data
    csv_lines = generate_clkmap_csv(connections, vpr_tile_grid)

    # Write the CSV file
    args.o.write("name,src.x,src.y,src.z,dst.x,dst.y,dst.z\n")
    args.o.write("\n".join(csv_lines) + "\n")


# =============================================================================

if __name__ == "__main__":
    main()
