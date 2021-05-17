#!/usr/bin/env python3
"""
A simple script that fixes up post-pnr verilog files from VPR:

 - Removes incorrect constants "1'b0" connected to unconnected cell port,

 - Disconnects all unconnected outputs from the "DummyOut" net,

 - appends a correct prefix for  each occurrence of a binary string in round
   brackets. For example "(010101)" is converted into "(6'b010101)".

One shortcoming of the script is that it may treat a decimal value of 10, 100
etc. as binary. Fortunately decimal literals haven't been observed to appear
in Verilog files written by VPR.
"""
import argparse
import re

# =============================================================================


def main():

    # Parse arguments
    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter
    )

    parser.add_argument(
        "-i", type=str, required=True, help="Input Verilog file"
    )
    parser.add_argument(
        "-o", type=str, required=True, help="Output Verilog file"
    )

    args = parser.parse_args()

    # Read the input verilog file
    with open(args.i, "r") as fp:
        code = fp.read()

    # Remove connection to 1'b0 from all ports. Do this before fixing up
    # binary string prefixes so binary parameters won't be affected
    code = re.sub(
        r"\.(?P<port>\w+)\s*\(\s*1'b0\s*\)", r".\g<port>(1'bZ)", code
    )

    # Remove connections to the "DummyOut" net
    code = re.sub(
        r"\.(?P<port>\w+)\s*\(\s*DummyOut\s*\)", r".\g<port>()", code
    )

    # Fixup multi-bit port connections
    def sub_func_1(match):
        port = match.group("port")
        conn = match.group("conn")

        conn = re.sub(r"1'b0", "1'bZ", conn)
        conn = re.sub(r"DummyOut", "", conn)

        return ".{}({{{}}})".format(port, conn)

    code = re.sub(
        r"\.(?P<port>\w+)\s*\(\s*{(?P<conn>[^}]*)}\s*\)", sub_func_1, code
    )

    # Prepend binary literal prefixes
    def sub_func(match):
        assert match is not None
        value = match.group("val")

        # Collapse separators "_"
        value = value.replace("_", "")

        # Add prefix, format the final string
        lnt = len(value)
        return "({}'b{})".format(lnt, value)

    code = re.sub(r"\(\s*(?P<val>[01_]+)\s*\)", sub_func, code)

    # Write the output verilog file
    with open(args.o, "w") as fp:
        fp.write(code)


# =============================================================================

if __name__ == "__main__":
    main()
