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

    is_header = True
    for pkg_pin_name, pkg_pins in package_pinmap.items():
        for pkg_pin in pkg_pins:
            if pkg_pin.alias is not None:
                if is_header:
                    csv_lines.append("name,x,y,z,type,alias\n")
                    is_header = False

                line = "{},{},{},0,{},{}".format(
                    pkg_pin.name,
                    pkg_pin.loc.x,
                    pkg_pin.loc.y,
                    pkg_pin.cell.type,
                    pkg_pin.alias
                )
                csv_lines.append(line)
            else:
                if is_header:
                    csv_lines.append("name,x,y,z,type\n")
                    is_header = False

                line = "{},{},{},0,{}".format(
                    pkg_pin.name,
                    pkg_pin.loc.x,
                    pkg_pin.loc.y,
                    pkg_pin.cell.type
                )
                csv_lines.append(line)

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
        "--package",
        type=str,
        default="PD64",
        help="Package name to generate the pinmap for"
    )
    parser.add_argument(
        "-o",
        type=argparse.FileType("w"),
        default="pinmap.csv",
        help="Output pinmap CSV file"
    )

    args = parser.parse_args()

    # Load data from the database
    db = pickle.load(args.db)
    package_pinmaps = db["vpr_package_pinmaps"]

    # Generate the CSV data
    csv_lines = generate_pinmap_csv(package_pinmaps[args.package])

    # Write the pinmap CSV file
    #args.o.write("name,x,y,z,type\n")
    args.o.write("\n".join(csv_lines) + "\n")


# =============================================================================

if __name__ == "__main__":
    main()
