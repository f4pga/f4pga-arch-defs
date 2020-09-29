#!/usr/bin/env python3
""" Generates the top level VPR arch XML from the Project U-Ray database.

By default this will generate a complete arch XML for all tile types specified.

If the --use_roi flag is passed, only the tiles within the ROI will be included,
and synthetic IO pads will be created and connected to the routing fabric.
The mapping of the pad name to synthetic tile location will be outputted to the
file specified in the --synth_tiles output argument.  This can be used to generate
IO placement spefications to target the synthetic IO pads.

"""
import argparse
import simplejson as json

import prjuray.db

from arch_import import arch_import

# =============================================================================

# Map instance type (e.g. IOB_X1Y10) to:
# - Which coordinates are required (e.g. X, Y or X and Y)
# - Modulus on the coordinates
#
# For example, IO sites only need the Y coordinate, use a modulus of 2.
# So IOB_X1Y10 becomes IOB_Y0, IOB_X1Y11 becomes IOB_Y1, etc.
PREFIX_REQUIRED = {
}


def main():

    parser = argparse.ArgumentParser(description="Generate arch.xml")
    parser.add_argument(
        '--db_root',
        required=True,
        help="Project U-Ray database to use."
    )
    parser.add_argument(
        '--part',
        required=True,
        help="FPGA part"
    )
    parser.add_argument(
        '--output-arch',
        nargs='?',
        type=argparse.FileType('w'),
        help="""File to output arch."""
    )
    parser.add_argument(
        '--tile-types',
        required=True,
        help="Semi-colon seperated tile types."
    )
    parser.add_argument(
        '--pb_types',
        required=True,
        help="Semi-colon seperated pb_types types."
    )
    parser.add_argument(
        '--pin_assignments',
        required=True,
        type=argparse.FileType('r')
    )
    parser.add_argument(
        '--device',
        required=True
    )
    parser.add_argument(
        '--synth_tiles',
        required=False
    )
    parser.add_argument(
        '--connection_database',
        required=True
    )
    parser.add_argument(
        '--graph_limit',
        help='Limit grid to specified dimensions in x_min,y_min,x_max,y_max',
    )

    args = parser.parse_args()

    # Read database
    db = prjuray.db.Database(args.db_root, args.part)

    # Use graph limit
    roi = None
    if args.graph_limit:
        roi = tuple(map(int, args.graph_limit.split(',')))

    # Import arch
    arch_import(args, db, roi, False, False, PREFIX_REQUIRED)


if __name__ == '__main__':
    main()
