#!/usr/bin/env python3
"""
The generator
"""
import argparse

# =============================================================================

PINOUT = [
    # Basys3 JB
    "A14",
    "A16",
    "B15",
    "B16",
    "A15",
    "A17",
    "C15",
    "C16",
    # Basys3 JC
    "K17",
    "M18",
    "N17",
    "P18",
    "L17",
    "M19",
    "P17",
    "R18"
]

def generate_output(iostandard, drives, slews):

    num_outputs = len(drives) * len(slews)

    # Header
    verilog = """
module top(
    input  wire clk,
    output wire [{}:0] out
);
""".format(num_outputs-1)

    pcf = """
set_io clk W5
"""

    # 100Hz square wave generator
    verilog += """
    wire        clk_bufg;
    wire [31:0] cnt_ps;
    reg         tick;

    BUFG bufg (.I(clk), .O(clk_bufg));

    initial cnt_ps <= 0;
    initial tick   <= 0;

    always @(posedge clk_bufg)
        if (clk_bufg >= (100000000 / (2*100)) - 1)
            cnt_ps <= 0;
            tick   <= !tick;
        else
            cnt_ps <= cnt_ps + 1;
            tick   <= tick;
"""

    # Output buffers
    index = 0
    for slew in slews:
        for drive in drives:

            params = {
                "IOSTANDARD": "\"{}\"".format(iostandard)
            }

            if drive is not None and drive != "0":
                params["DRIVE"] = str(drive)

            if slew is not None:
                params["SLEW"] = "\"{}\"".format(slew)

            verilog += """
    OBUF # ({params}) obuf_{index} (
    .I(tick),
    .O(out[{index}])
    );
            """.format(
                params = ",".join([".{}({})".format(k, v) for k, v in params.items()]),
                index = index
            )

            pcf += "set_io out[{}] {}\n".format(
                index,
                PINOUT[index]
            )

            index += 1

    # Footer
    verilog += """
endmodule
"""

    return verilog, pcf

# =============================================================================

def main():

    # Parse arguments
    parser = argparse.ArgumentParser()
    parser.add_argument("--mode", required=True, help="Generation mode")
    parser.add_argument("--iostandard", required=True, help="IOSTANDARD")
    parser.add_argument("--drive", required=False, nargs="+", help="DRIVE(s)")
    parser.add_argument("--slew", required=False, nargs="+", help="SLEW(s)")
    parser.add_argument("-o", required=True, help="Design name")

    args = parser.parse_args()

    # Generate design for output IO settings
    if args.mode == "output":
        verilog, pcf = generate_output(args.iostandard, args.drive, args.slew)
    else:
        raise RuntimeError("Unknown generation mode '{}'".format(args.mode))

    # Write verilog
    with open(args.o + ".v", "w") as fp:
        fp.write(verilog)

    # Write PCF
    with open(args.o + ".pcf", "w") as fp:
        fp.write(pcf)

if __name__ == "__main__":
    main()
