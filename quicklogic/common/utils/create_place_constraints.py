#!/usr/bin/env python3
import argparse
import sys
import csv

import eblif

# =============================================================================

CELL_PAIRS = {
    "pp3": [
        {
        "iob": ("CLOCK_CELL", "I_PAD", "O_CLK"),
        "buf": ("GMUX_IP", "IP", "IZ"),
        },
    ],

    "ap3": [
        {
        "iob": ("CLOCK", "I_PAD", "O_CLK"),
        "buf": ("GMUX_CLK", "GCLKIN", "IZ"),
        }
    ],
}

# =============================================================================


def main():
    parser = argparse.ArgumentParser(
        description='Creates placement constraints other than IOs'
    )

    parser.add_argument(
        "--input",
        '-i',
        "-I",
        type=argparse.FileType('r'),
        default=sys.stdin,
        help='The input constraints place file.'
    )
    parser.add_argument(
        "--output",
        '-o',
        "-O",
        type=argparse.FileType('w'),
        default=sys.stdout,
        help='The output constraints place file.'
    )
    parser.add_argument(
        "-f",
        "--family",
        type=str,
        required=True,
        choices=["pp3", "ap3"],
        help="Device family"
    )
    parser.add_argument(
        "--map",
        type=argparse.FileType('r'),
        required=True,
        help="Clock pinmap CSV file"
    )
    parser.add_argument(
        "--blif",
        '-b',
        type=argparse.FileType('r'),
        required=True,
        help='BLIF / eBLIF file.'
    )

    args = parser.parse_args()

    # Load clock map
    clkmap = {}
    for row in csv.DictReader(args.map):
        name = row["name"]
        src_loc = (
            int(row["src.x"]),
            int(row["src.y"]),
            int(row["src.z"]),
        )
        dst_loc = (
            int(row["dst.x"]),
            int(row["dst.y"]),
            int(row["dst.z"]),
        )

        clkmap[src_loc] = (dst_loc, name)

    # Load EBLIF
    eblif_data = eblif.parse_blif(args.blif)

    # Process the IO constraints file. Pass the constraints unchanged, store
    # them.
    io_constraints = {}

    for line in args.input:

        # Strip, skip comments
        line = line.strip()
        if line.startswith("#"):
            continue

        args.output.write(line + "\n")

        # Get block and its location
        block, x, y, z = line.split()[0:4]
        io_constraints[block] = (
            int(x),
            int(y),
            int(z),
        )

    # Analyze the BLIF netlist. Find clock inputs that go through a known IOB
    # cell to a known clock buffer cell
    clock_connections = []

    cell_pairs = CELL_PAIRS[args.family]
    for cell_pair in cell_pairs:

        iob_type, iob_inp, iob_out = cell_pair["iob"]
        buf_type, buf_inp, buf_out = cell_pair["buf"]

        for inp_net in eblif_data["inputs"]["args"]:

            # This one is not constrained, skip it
            if inp_net not in io_constraints:
                continue

            # Search for an IOB cell connected to that net
            for cell in eblif_data["subckt"]:
                if cell["type"] == "subckt" and cell["args"][0] == iob_type:
                    pattern = "{}={}".format(iob_inp, inp_net)

                    try:
                        idx = cell["args"].index(pattern)
                        iob_cell = cell
                        break
                    except ValueError:
                        pass

            else:
                continue

            # Get the IOB to BUF net
            for i in range(1, len(iob_cell["args"])):
                pin, net = iob_cell["args"][i].split("=")

                if pin == iob_out:
                    con_net = net
                    break

            else:
                continue

            # Search for a BUF connected to the IOB cell
            for cell in eblif_data["subckt"]:
                if cell["type"] == "subckt" and cell["args"][0] == buf_type:
                    pattern = "{}={}".format(buf_inp, con_net)

                    try:
                        idx = cell["args"].index(pattern)
                        buf_cell = cell
                        break
                    except ValueError:
                        pass
            else:
                continue

            # Get the output net of the BUF
            for i in range(1, len(buf_cell["args"])):
                pin, net = buf_cell["args"][i].split("=")

                if pin == buf_out:
                    clk_net = net
                    break

            else:
                continue

            # Store data
            clock_connections.append(
                (inp_net, iob_cell, con_net, buf_cell, clk_net)
            )

    # Emit constraints for BUF cells
    for inp_net, iob_cell, con_net, buf_cell, clk_net in clock_connections:

        src_loc = io_constraints[inp_net]
        if src_loc not in clkmap:
            print(
                "ERROR: No {} location fro input {} pad for net '{}' at {}"
                .format(buf_cell["args"][0], iob_cell["args"][0], inp_net, src_loc)
            )
            continue

        dst_loc, name = clkmap[src_loc]

        # FIXME: Silently assuming here that VPR will name the GMUX block as
        # the GMUX cell in EBLIF. In order to fix that there will be a need
        # to read & parse the packed netlist file.
        line = "{} {} {} {} # {}\n".format(
            buf_cell["cname"][0], *dst_loc, name
        )
        args.output.write(line)


# =============================================================================

if __name__ == '__main__':
    main()
