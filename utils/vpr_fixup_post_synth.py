#!/usr/bin/env python3
"""
A simple script that fixes up post-pnr verilog and SDF files from VPR:

 - Removes incorrect constants "1'b0" connected to unconnected cell port,

 - Disconnects all unconnected outputs from the "DummyOut" net,

 - appends a correct prefix for  each occurrence of a binary string in round
   brackets. For example "(010101)" is converted into "(6'b010101)".

When the option "--split-ports" is given the script also breaks all references
to wide cell ports into references to individual pins.

One shortcoming of the script is that it may treat a decimal value of 10, 100
etc. as binary. Fortunately decimal literals haven't been observed to appear
in Verilog files written by VPR.
"""
import argparse
import os
import re

# =============================================================================


def split_verilog_ports(code):
    """
    Splits assignments of individual nets to wide cell ports into assignments
    of those nets to 1-bit wide cell ports. Effectively splits cell ports as
    well.
    """

    def sub_func(match):
        port = match.group("port")
        conn = match.group("conn").strip().replace("\n", "")

        # Get individual signals
        signals = [s.strip() for s in conn.split(",")]

        # Format new port connections
        conn = []
        for i, signal in enumerate(signals):
            j = len(signals) - 1 - i
            conn.append(".\\{}[{}] ({} )".format(port, j, signal))

        conn = ", ".join(conn)
        return conn

    code = re.sub(
        r"\.(?P<port>\S+)\s*\(\s*{(?P<conn>[^}]+)}\s*\)",
        sub_func,
        code,
        flags=re.DOTALL
    )
    return code


def split_sdf_ports(code):
    """
    Escapes square brackets in port names given in delay path specifications
    which results of indexed multi-bit ports being represented as individual
    single-bit ones.
    """

    def sub_func(match):
        return match.group(0).replace("[", "\\[").replace("]", "\\]")

    code = re.sub(
        r"\((?P<keyword>SETUP|HOLD|IOPATH)\s+"
        r"(?P<port1>(\([^\)]*\))|\S+)\s+(?P<port2>(\([^\)]*\))|\S+)", sub_func,
        code
    )
    return code


# =============================================================================


def main():

    # Parse arguments
    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter
    )

    parser.add_argument(
        "--vlog-in", type=str, default=None, help="Input Verilog file"
    )
    parser.add_argument(
        "--vlog-out", type=str, default=None, help="Output Verilog file"
    )
    parser.add_argument(
        "--sdf-in", type=str, default=None, help="Input SDF file"
    )
    parser.add_argument(
        "--sdf-out", type=str, default=None, help="Output SDF file"
    )
    parser.add_argument(
        "--split-ports", action="store_true", help="Split multi-bit ports"
    )

    args = parser.parse_args()

    # Check args
    if not args.vlog_in and not args.sdf_in:
        print("Please provide at least one of --vlog-in, --sdf-in")
        exit(1)

    # Process Verilog netlist
    if args.vlog_in:

        # Read the input verilog file
        with open(args.vlog_in, "r") as fp:
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

        # Split ports
        if args.split_ports:
            code = split_verilog_ports(code)

        # Write the output verilog file
        fname = args.vlog_out
        if not fname:
            root, ext = os.path.splitext(args.vlog_in)
            fname = "{}.fixed{}".format(root, ext)

        with open(fname, "w") as fp:
            fp.write(code)

    # Process SDf file
    if args.sdf_in:

        # Read the input SDF file
        with open(args.sdf_in, "r") as fp:
            code = fp.read()

        # Split ports
        if args.split_ports:
            code = split_sdf_ports(code)

        # Write the output SDF file
        fname = args.sdf_out
        if not fname:
            root, ext = os.path.splitext(args.sdf_in)
            fname = "{}.fixed{}".format(root, ext)

        with open(fname, "w") as fp:
            fp.write(code)


# =============================================================================

if __name__ == "__main__":
    main()
