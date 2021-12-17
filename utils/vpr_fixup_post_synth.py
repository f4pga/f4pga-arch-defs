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


def merge_verilog_ports(code):

    to_merge = {}

    def module_def_sub_func(match):
        """
        Replaces single bit ports with multi-bit ports in module IO definition
        """

        def replace_ports(match):
            """
            Creates single multi-bit port definition
            """
            base = match.group("base")
            port_def = "\n    {} [{}:{}] {},".format(
                to_merge[base]["direction"], to_merge[base]["max"],
                to_merge[base]["min"], base
            )
            return port_def

        module_def_s = match.group(0)

        # Find all single bit ports that can be converted to multi bit ones
        matches = re.finditer(
            r"\s*(?P<direction>(input|output|inout))\s+"
            r"(?P<port>\\(?P<base>\S+)\[(?P<index>[0-9]+)\])", module_def_s
        )
        # Gather data about ports
        for match in matches:
            if (match is not None):
                base = match.group("base")
                index = match.group("index")
                direction = match.group("direction")
                if (base in to_merge.keys()):
                    assert direction == to_merge[base][
                        "direction"
                    ], "Port direction inconsistency for port {}".format(base)
                    to_merge[base]["ids"].append(int(index))
                    if (int(index) < to_merge[base]["min"]):
                        to_merge[base]["min"] = int(index)
                    if (int(index) > to_merge[base]["max"]):
                        to_merge[base]["max"] = int(index)
                else:
                    to_merge[base] = {
                        "direction": direction,
                        "ids": [int(index)],
                        "min": int(index),
                        "max": int(index)
                    }

        # Check index consistency
        for base, specs in to_merge.items():
            specs["ids"].sort()
            assert list(
                range(specs["min"], specs["max"] + 1)
            ) == specs["ids"], "Port indexes inconsistency for port {}".format(
                base
            )

        # Replace zero-indexed ports with multi-bit ports
        module_def_s = re.sub(
            r"\s*(?P<direction>(input|output|inout))\s+"
            r"(?P<port>\\(?P<base>\S+)\[(?P<index>0)\]\s*,?)", replace_ports,
            module_def_s
        )

        # remove non-zero-indexed ports
        module_def_s = re.sub(
            r"\s*(?P<direction>(input|output|inout))\s+"
            r"(?P<port>\\(?P<base>\S+)\[(?P<index>[1-9]+[0-9]*)\]\s*,?)", "",
            module_def_s
        )

        # Ensure that there is no colon at the last line of the module IO definition
        module_def_s = re.sub(r",\s*\)\s*;", ");", module_def_s)

        return module_def_s

    def port_usage_sub_func(match):
        """
        Creates single multi-bit port definition
        """
        base = match.group("base")
        index = match.group("index")
        trailing_ws = match.group(0)[-1]
        port_usage = "{}[{}]{}".format(base, index, trailing_ws)
        return port_usage

    # Find module IO definition and substitute it
    code = re.sub(
        r"\s*module\s+\S+\s*\([\s\S]*?\);",
        module_def_sub_func,
        code,
        flags=re.DOTALL
    )

    # Find all other occurances of excaped identifiers for single bit ports
    # and substitute them with indexed multi bit ports
    code = re.sub(
        r"\\(?P<base>\S+)\[(?P<index>[0-9]+)\]\s",
        port_usage_sub_func,
        code,
        flags=re.DOTALL
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

        # Write the output verilog file
        fname = args.vlog_out
        if not fname:
            root, ext = os.path.splitext(args.vlog_in)
            fname = "{}.fixed{}".format(root, ext)

        # Split ports
        if args.split_ports:
            code = split_verilog_ports(code)
            with open(fname, "w") as fp:
                fp.write(code)

            # Make sure ports are not split
            code = merge_verilog_ports(code)
            root, ext = os.path.splitext(fname)
            fname = "{}.no_split{}".format(root, ext)

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
