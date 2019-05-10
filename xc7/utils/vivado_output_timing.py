""" Utility for generating TCL script to output timing information from a
design checkpoint.
"""
import argparse


def create_runme(f_out, args):
    print(
        """
report_timing_summary

source {util_tcl}
write_timing_info timing_{name}.json5
""".format(name=args.name, util_tcl=args.util_tcl),
        file=f_out
    )


def main():
    parser = argparse.ArgumentParser(description=__doc__)

    parser.add_argument('--name', required=True)
    parser.add_argument('--util_tcl', required=True)
    parser.add_argument('--output_tcl', required=True)

    args = parser.parse_args()
    with open(args.output_tcl, 'w') as f:
        create_runme(f, args)


if __name__ == "__main__":
    main()
