""" Utility for generating TCL script to output timing information from a
design checkpoint.
"""
import argparse


def create_output_timing(f_out, args):
    print(
        """
source {util_tcl}
write_timing_info timing_{name}.json5

report_timing_summary
""".format(name=args.name, util_tcl=args.util_tcl),
        file=f_out
    )


def main():
    parser = argparse.ArgumentParser(description=__doc__)

    parser.add_argument(
        '--name', help="Name to postfix outputs.", required=True
    )
    parser.add_argument(
        '--util_tcl',
        help="Path to TCL script containing timing utilities.",
        required=True
    )
    parser.add_argument(
        '--output_tcl', help="Filename of output TCL file.", required=True
    )

    args = parser.parse_args()
    with open(args.output_tcl, 'w') as f:
        create_output_timing(f, args)


if __name__ == "__main__":
    main()
