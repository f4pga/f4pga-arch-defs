import argparse
"""
Currently, litex outputs XDC constraints in which the create_clock commands
cannot be correctly parsed yet by the XDC yosys plugin.

Example of failing XDC command:
    create_clock -name clk100 -period 10.0 [get_nets clk100]

Example of working XDC command:
    create_clock -period 10.0 clk100

This script fixes the generated XDC and translates the failing commands
into the working ones.

This script is a temporary workaround and needs to be avoided.
"""


def main():
    parser = argparse.ArgumentParser(
        description="Fixup script to modify the XDC output of LiteX"
    )
    parser.add_argument("--xdc", required=True)

    args = parser.parse_args()

    lines_to_add = []
    with open(args.xdc, "r") as xdc:
        lines = xdc.readlines()

        processing = False
        for line in lines:
            if 'Clock constraints' in line:
                processing = True

            if processing:
                if line.startswith('create_clock'):
                    groups = line.split()

                    # Old line: create_clock -name clk100 -period 10.0 [get_nets clk100]
                    # New line: create_clock -period 10.0 clk100
                    new_line = " ".join(
                        [groups[0], groups[3], groups[4], groups[2], '\n']
                    )

                    lines_to_add.append(new_line)
            else:
                lines_to_add.append(line)

    with open(args.xdc, "w") as xdc:
        for line in lines_to_add:
            xdc.write(line)


if __name__ == "__main__":
    main()
