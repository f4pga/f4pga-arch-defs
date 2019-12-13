#!/usr/bin/env python3
"""
The generator
"""
import argparse
import simplejson as json

# =============================================================================

PINOUT = {
    "basys3":
        {
            "clock":
                "W5",
            "led":
                [
                    "U16",
                    "E19",
                    "U19",
                    "V19",
                    "W18",
                    "U15",
                    "U14",
                    "V14",
                    "V13",
                    "V3",
                    "W3",
                    "U3",
                    "P3",
                    "N3",
                    "P1",
                    "L1",
                ],
            "external":
                [
                    # Basys3 JB 1-4, 7-10
                    "A14",
                    "A16",
                    "B15",
                    "B16",
                    "A15",
                    "A17",
                    "C15",
                    "C16",
                    # Basys3 JC 1-4, 7-10
                    "K17",
                    "M18",
                    "N17",
                    "P18",
                    "L17",
                    "M19",
                    "P17",
                    "R18"
                ],
        },
    "arty":
        {
            "clock":
                "E3",
            "led":
                [
                    "G6",  # R0
                    "G3",  # R1
                    "J3",  # R2
                    "K1",  # R3
                    "F6",  # G0
                    "J4",  # G1
                    "J2",  # G2
                    "H6",  # G3
                    "E1",  # B0
                    "G4",  # B1
                    "H4",  # B2
                    "K2",  # B3
                    "H5",  # LED4
                    "J5",  # LED5
                    "T9",  # LED6
                    "T10",  # LED7
                ],
            "external":
                [
                    # Pmod JB
                    "E15",
                    "E16",
                    "D15",
                    "C15",
                    "J17",
                    "J18",
                    "K15",
                    "J15",
                    # Pmod JC
                    "U12",
                    "V12",
                    "V10",
                    "V11",
                    "U14",
                    "V14",
                    "T13",
                    "U13",
                ],
        },
}


def unquote(s):
    if isinstance(s, str):
        return s.replace("\"", "")
    return s


def generate_output(board, iostandard, drives, slews):
    """
    Generates a design which outputs 100Hz square wave to a number of pins
    in which each one has different DRIVE+SLEW setting. The IOSTANDARD is
    common for all of them.
    """

    num_outputs = len(drives) * len(slews)
    iosettings = {}

    # Header
    verilog = """
module top(
    input  wire clk,
    output wire [{}:0] out
);
""".format(num_outputs - 1)

    pcf = """
set_io clk {}
""".format(PINOUT[board]["clock"])

    # 100Hz square wave generator
    verilog += """
    wire        clk_bufg;
    reg  [31:0] cnt_ps;
    reg         tick;

    BUFG bufg (.I(clk), .O(clk_bufg));

    initial cnt_ps <= 0;
    initial tick   <= 0;

    always @(posedge clk_bufg)
        if (cnt_ps >= (100000000 / (2*100)) - 1) begin
            cnt_ps <= 0;
            tick   <= !tick;
        end else begin
            cnt_ps <= cnt_ps + 1;
            tick   <= tick;
        end
"""

    # Output buffers
    index = 0
    for slew in slews:
        for drive in drives:

            params = {"IOSTANDARD": "\"{}\"".format(iostandard)}

            if drive is not None and drive != "0":
                params["DRIVE"] = int(drive)

            if slew is not None:
                params["SLEW"] = "\"{}\"".format(slew)

            pin = PINOUT[board]["external"][index]

            verilog += """
    OBUF # ({params}) obuf_{index} (
    .I(tick),
    .O(out[{index}])
    );
            """.format(
                params=",".join(
                    [".{}({})".format(k, v) for k, v in params.items()]
                ),
                index=index
            )

            pcf += "set_io out[{}] {}\n".format(index, pin)

            iosettings[pin] = {k: unquote(v) for k, v in params.items()}
            index += 1

    # Footer
    verilog += """
endmodule
"""

    return verilog, pcf, iosettings


def generate_input(board, iostandard, in_terms):
    """
    Generates a design with singnals from external pins go through IBUFs and
    registers to LEDs. Each IBUF has differen IN_TERM setting.
    """

    num_pins = len(in_terms)
    iosettings = {}

    # Header
    verilog = """
module top(
    input  wire clk,
    input  wire [{N}:0] inp,
    output reg  [{N}:0] led
);

    initial led <= 0;
""".format(N=num_pins - 1)

    pcf = """
set_io clk {}
""".format(PINOUT[board]["clock"])

    # BUFG
    verilog += """
    wire  clk_bufg;
    BUFG bufg (.I(clk), .O(clk_bufg));
"""

    # Input buffers + registers
    index = 0
    for in_term in in_terms:

        params = {
            "IOSTANDARD": "\"{}\"".format(iostandard),
            "IN_TERM": "\"{}\"".format(in_term)
        }

        pin = PINOUT[board]["external"][index]

        verilog += """
    wire inp_b[{index}];

    IBUF # ({params}) ibuf_{index} (
    .I(inp[{index}]),
    .O(inp_b[{index}])
    );

    always @(posedge clk_bufg)
        led[{index}] <= inp_b[{index}];
        """.format(
            params=",".join(
                [".{}({})".format(k, v) for k, v in params.items()]
            ),
            index=index
        )

        pcf += "set_io inp[{}] {}\n".format(index, pin)
        pcf += "set_io led[{}] {}\n".format(index, PINOUT[board]["led"][index])

        iosettings[pin] = {k: unquote(v) for k, v in params.items()}
        index += 1

    # Footer
    verilog += """
endmodule
"""

    return verilog, pcf, iosettings


def generate_inout(board, iostandard, drives, slews):
    """
    Generates a design with INOUT buffers. Buffers cycle through states:
    L,Z,H,Z with 100Hz frequency. During the Z state, IO pins are latched
    and their state is presented on LEDs.
    """

    num_pins = len(drives) * len(slews)
    iosettings = {}

    # Header
    verilog = """
module top(
    input  wire clk,
    inout  wire [{N}:0] ino,
    output reg  [{N}:0] led
);

    initial led <= 0;

    wire [{N}:0] ino_i;
    reg ino_o;
    reg ino_t;

""".format(N=num_pins - 1)

    pcf = """
set_io clk {}
""".format(PINOUT[board]["clock"])

    # Control signal generator, data sampler
    verilog += """
    wire        clk_bufg;
    reg  [31:0] cnt_ps;

    BUFG bufg (.I(clk), .O(clk_bufg));

    initial cnt_ps <= 32'd0;
    initial ino_o  <= 1'b0;
    initial ino_t  <= 1'b1;

    always @(posedge clk_bufg)
        if (cnt_ps >= (100000000 / (2*100)) - 1) begin
            cnt_ps <= 0;
            ino_t  <= !ino_t;
            if (ino_t == 1'b1)
                ino_o <= !ino_o;
        end else begin
            cnt_ps <= cnt_ps + 1;
            ino_t  <= ino_t;
            ino_o  <= ino_o;
        end

    always @(posedge clk_bufg)
        if (ino_t == 1'b1)
            led <= ino_i;
        else
            led <= led;
"""

    # INOUT buffers
    index = 0
    for slew in slews:
        for drive in drives:

            params = {"IOSTANDARD": "\"{}\"".format(iostandard)}

            if drive is not None and drive != "0":
                params["DRIVE"] = int(drive)

            if slew is not None:
                params["SLEW"] = "\"{}\"".format(slew)

            pin = PINOUT[board]["external"][index]

            verilog += """
    IOBUF # ({params}) iobuf_{index} (
    .I(ino_o),
    .O(ino_i[{index}]),
    .T(ino_t),
    .IO(ino[{index}])
    );
            """.format(
                params=",".join(
                    [".{}({})".format(k, v) for k, v in params.items()]
                ),
                index=index
            )

            pcf += "set_io ino[{}] {}\n".format(index, pin)
            pcf += "set_io led[{}] {}\n".format(
                index, PINOUT[board]["led"][index]
            )

            iosettings[pin] = {k: unquote(v) for k, v in params.items()}
            index += 1

    # Footer
    verilog += """
endmodule
"""

    return verilog, pcf, iosettings


# =============================================================================


def main():

    # Parse arguments
    parser = argparse.ArgumentParser()
    parser.add_argument("--board", required=True, help="Board")
    parser.add_argument("--mode", required=True, help="Generation mode")
    parser.add_argument("--iostandard", required=True, help="IOSTANDARD")
    parser.add_argument("--drive", required=False, nargs="+", help="DRIVE(s)")
    parser.add_argument("--slew", required=False, nargs="+", help="SLEW(s)")
    parser.add_argument(
        "--in_term", required=False, nargs="+", help="IN_TERM(s)"
    )
    parser.add_argument("-o", required=True, help="Design name")

    args = parser.parse_args()

    # Generate design for output IO settings
    if args.mode == "output":
        verilog, pcf, iosettings = generate_output(
            args.board, args.iostandard, args.drive, args.slew
        )
    elif args.mode == "input":
        verilog, pcf, iosettings = generate_input(
            args.board, args.iostandard, args.in_term
        )
    elif args.mode == "inout":
        verilog, pcf, iosettings = generate_inout(
            args.board, args.iostandard, args.drive, args.slew
        )
    else:
        raise RuntimeError("Unknown generation mode '{}'".format(args.mode))

    # Write verilog
    with open(args.o + ".v", "w") as fp:
        fp.write(verilog)

    # Write PCF
    with open(args.o + ".pcf", "w") as fp:
        fp.write(pcf)

    # Write iosettings
    if iosettings is not None:
        with open(args.o + ".json", "w") as fp:
            json.dump(iosettings, fp, indent=2)


if __name__ == "__main__":
    main()
