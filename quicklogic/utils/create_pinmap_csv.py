#!/usr/bin/env python3
import argparse
import pickle

#from data_structs import *

# =============================================================================

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
        "-o",
        type=str,
        default="pinmap.csv",
        help="Output pinmap CSV file"
    )

    args = parser.parse_args()

    # Load data from the database
    with open(args.db, "rb") as fp:
        db = pickle.load(fp)

    # Write the pinmap CSV file
    with open(args.o, "w") as fp:
        
        # Header
        fp.write("name,x,y,z,is_clock,is_input,is_output,iob\n")

# =============================================================================


if __name__ == "__main__":
    main()
