#!/usr/bin/env python3
import argparse

# ============================================================================


def main():

    # Parse args
    parser = argparse.ArgumentParser(
        description="Generates top-level verilog for scalable processing test"
    )
    parser.add_argument('--top-name', type=str, default=None)
    parser.add_argument(
        '--num-processing-units', type=int, default=1, required=True
    )
    parser.add_argument('--template', type=str, default="basys3_top.v")

    args = parser.parse_args()

    # Read template
    with open(args.template, "r") as fp:
        template = fp.readlines()

    # Find a line with "NUM_PROCESSING_UNITS" and change it
    verilog = []
    for line in template:
        line = line.strip()

        if "NUM_PROCESSING_UNITS" in line:
            verilog.append(
                ".NUM_PROCESSING_UNITS   (%d)," % args.num_processing_units
            )
        elif args.top_name is not None and "module top" in line:
            verilog.append("module %s" % args.top_name)
        else:
            verilog.append(line)

    # Spit out the code
    for line in verilog:
        print(line)


# ============================================================================

if __name__ == '__main__':
    main()
