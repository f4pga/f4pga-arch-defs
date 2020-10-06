#!/usr/bin/env python3
""" Generates the top level VPR arch XML from the Project X-Ray database.

By default this will generate a complete arch XML for all tile types specified.

If the --use_roi flag is passed, only the tiles within the ROI will be included,
and synthetic IO pads will be created and connected to the routing fabric.
The mapping of the pad name to synthetic tile location will be outputted to the
file specified in the --synth_tiles output argument.  This can be used to generate
IO placement spefications to target the synthetic IO pads.

"""
import argparse
import simplejson as json

import prjxray.db
from prjxray.roi import Roi
from prjxray.overlay import Overlay

from arch_import import arch_import

# =============================================================================

# Map instance type (e.g. IOB_X1Y10) to:
# - Which coordinates are required (e.g. X, Y or X and Y)
# - Modulus on the coordinates
#
# For example, IO sites only need the Y coordinate, use a modulus of 2.
# So IOB_X1Y10 becomes IOB_Y0, IOB_X1Y11 becomes IOB_Y1, etc.
PREFIX_REQUIRED = {
    "IOB": ("Y", 2),
    "IDELAY": ("Y", 2),
    "ILOGIC": ("Y", 2),
    "OLOGIC": ("Y", 2),
    "BUFGCTRL": ("XY", (2, 16)),
    "SLICEM": ("X", 2),
    "SLICEL": ("X", 2),
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
    parser.add_argument(
        '--use_roi',
        required=False
    )
    parser.add_argument(
        '--use_overlay',
        required=False
    )

    args = parser.parse_args()

    # Read database
    db = prjxray.db.Database(args.db_root, args.part)

    # Determine ROI type
    roi = None
    if args.use_roi:

        with open(args.use_roi) as f:
            j = json.load(f)

        with open(args.synth_tiles) as f:
            synth_tiles = json.load(f)

        roi = Roi(
            db=db,
            x1=j['info']['GRID_X_MIN'],
            y1=j['info']['GRID_Y_MIN'],
            x2=j['info']['GRID_X_MAX'],
            y2=j['info']['GRID_Y_MAX'],
        )

    elif args.use_overlay:

        with open(args.use_overlay) as f:
            j = json.load(f)

        with open(args.synth_tiles) as f:
            synth_tiles = json.load(f)

        region_dict = dict()
        for r in synth_tiles['info']:
            bounds = (
                r['GRID_X_MIN'], r['GRID_X_MAX'], r['GRID_Y_MIN'],
                r['GRID_Y_MAX']
            )
            region_dict[r['name']] = bounds

        roi = Overlay(region_dict=region_dict)

    elif args.graph_limit:
        roi = tuple(map(int, args.graph_limit.split(',')))

    # Import arch
    arch_import(args, db, roi, args.use_roi, args.use_overlay, PREFIX_REQUIRED)


if __name__ == '__main__':
    main()

