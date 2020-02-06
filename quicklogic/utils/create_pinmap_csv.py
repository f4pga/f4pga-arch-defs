#!/usr/bin/env python3
import argparse
import pickle

from data_structs import *

# =============================================================================


def generate_pinmap_csv(package_pinmap):
    """
    Generates content of the package pins CSV file.
    """
    csv_lines = []

    for pkg_pin_name, pkg_pin in package_pinmap.items():
        line = "{},{},{},0".format(pkg_pin.name, pkg_pin.loc.x, pkg_pin.loc.y)
        csv_lines.append(line)

    return csv_lines

# =============================================================================


def main():
    
    # Parse arguments
    parser = argparse.ArgumentParser(description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter)

    parser.add_argument(
        "--db",
        type=str,
        required=True,
        help="Input VPR database file of the device"
    )
    parser.add_argument(
        "--package",
        type=str,
        default="PU90",
        help="Package name to generate the pinmap for"
    )
    parser.add_argument(
        "-o",
        type=str,
        default="pinmap.csv",
        help="Output pinmap CSV file"
    )

    args = parser.parse_args()

    # Load data from the database
    with open(args.db, "rb") as fp:
        db = pickle.load(fp)
        package_pinmaps = db["vpr_package_pinmaps"]

    # Generate the CSV data
    csv_lines = generate_pinmap_csv(
        package_pinmaps[args.package]
    )

    # Write the pinmap CSV file
    with open(args.o, "w") as fp:
        fp.write("name,x,y,z\n")
        fp.write("\n".join(csv_lines))

# =============================================================================


if __name__ == "__main__":
    main()
