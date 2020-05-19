#!/usr/bin/env python3
"""
The generator
"""
import argparse

# =============================================================================

PINOUT = {
    "basys3-full":
        {
            "clock": "W5",
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
            "single-ended":
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
            "differential":
                [
                    # Basys3 JB
                    ("A14", "A15"),
                    ("A16", "A17"),
                    ("C15", "B15"),
                    ("B16", "C16"),
                    # Basys3 JC
                    ("M19", "M18"),
                    ("K17", "L17"),
                    ("N17", "P17"),
                    ("P18", "R18"),
                ],
            "iobanks": [16, 14],
        },
    "arty-full":
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
            "single-ended":
                [
                    # Pmod JB
                    (15, "E15"),
                    (15, "E16"),
                    (15, "D15"),
                    (15, "C15"),
                    (15, "J17"),
                    (15, "J18"),
                    (15, "K15"),
                    (15, "J15"),
                    # Pmod JC
                    (14, "U12"),
                    (14, "V12"),
                    (14, "V10"),
                    (14, "V11"),
                    (14, "U14"),
                    (14, "V14"),
                    (14, "T13"),
                    (14, "U13"),
                ],
            "differential":
                [
                    # Pmod JB
                    (15, "E15", "E16"),
                    (15, "D15", "C15"),
                    (15, "J17", "J18"),
                    (15, "K15", "J15"),
                    # Pmod JC
                    (15, "U12", "V12"),
                    (15, "V10", "V11"),
                    (15, "U14", "V14"),
                    (15, "T13", "U13"),
                ]
        },

    # Pinout for "bottom" routing graph of 50t, only for Basys3. These pins may
    # not correspond to actual LEDs so the design may not be suitable for testing
    # on hardware but it will pass all the checks on CI.
    "basys3-bottom":
        {
            "clock": "W5",  # Bank 34
            "led":
                [
                    "V3",  # LED9
                    "W3",  # LED10
                    "U3",  # LED11
                    "W7",  # CA
                    "W6",  # CB
                    "U8",  # CC
                    "V8",  # CD
                    "U5",  # CE
                    "V5",  # CF
                    "U7",  # CG
                ],
            "single-ended":
                [
                    # Basys3 JC 1-4, 7-10
                    "K17",
                    "M18",
                    "N17",
                    "P18",
                    "L17",
                    "M19",
                    "P17",
                    "R18",
                    "U15",  # LEDs
                    "U16",
                    "V13",
                    "V14",
                ],
            "differential":
                [
                    # Basys3 JC
                    ("M18", "M19"),
                    ("L17", "K17"),
                    ("P17", "N17"),
                    ("R18", "P18"),
                ],
            "iobanks": [14],
        },
}


def unquote(s):
    if isinstance(s, str):
        return s.replace("\"", "")
    return s


# =============================================================================


def generate_output(board, iostandard, drives, slews):
    """
    Generates a design which outputs 100Hz square wave to a number of pins
    in which each one has different DRIVE+SLEW setting. The IOSTANDARD is
    common for all of them.
    """

    num_ports = len(drives) * len(slews)
    iosettings = {}

    # Header
    verilog = """
module top(
    input  wire clk,
    output wire [{}:0] out
);
""".format(num_ports - 1)

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

            if drive is not None:
                params["DRIVE"] = int(drive)

            if slew is not None:
                params["SLEW"] = "\"{}\"".format(slew)

            pin = PINOUT[board]["single-ended"][index][1]

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

            if num_ports > 1:
                pcf += "set_io out[{}] {}\n".format(index, pin)
            else:
                pcf += "set_io out {}\n".format(pin)

            iosettings[pin] = {k: unquote(v) for k, v in params.items()}
            index += 1

    # Footer
    verilog += """
endmodule
"""

    return verilog, pcf, "", iosettings


def generate_input(board, iostandard, in_terms, vref):
    """
    Generates a design with singnals from external pins go through IBUFs and
    registers to LEDs. Each IBUF has differen IN_TERM setting.
    """

    num_ports = len(in_terms)
    iosettings = {}
    used_iobanks = set()

    # Header
    verilog = """
module top(
    input  wire clk,
    input  wire [{N}:0] inp,
    output reg  [{N}:0] led
);

    initial led <= 0;
""".format(N=num_ports - 1)

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
        }

        if in_term is not None:
            params["IN_TERM"] = "\"{}\"".format(in_term)

        iobank, pin = PINOUT[board]["single-ended"][index]
        used_iobanks.add(iobank)

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

        if num_ports > 1:
            pcf += "set_io inp[{}] {}\n".format(index, pin)
            pcf += "set_io led[{}] {}\n".format(
                index, PINOUT[board]["led"][index]
            )
        else:
            pcf += "set_io inp {}\n".format(pin)
            pcf += "set_io led {}\n".format(PINOUT[board]["led"][index])

        iosettings[pin] = {k: unquote(v) for k, v in params.items()}
        index += 1

    # Footer
    verilog += """
endmodule
"""

    # VREF
    tcl = ""
    if vref is not None:
        for iobank in used_iobanks:
            tcl += "set_property INTERNAL_VREF {} [get_iobanks {}]\n".format(
                vref, iobank
            )

    return verilog, pcf, tcl, iosettings


def generate_inout(board, iostandard, drives, slews, vref):
    """
    Generates a design with INOUT buffers. Buffers cycle through states:
    L,Z,H,Z with 100Hz frequency. During the Z state, IO pins are latched
    and their state is presented on LEDs.
    """

    num_ports = len(drives) * len(slews)
    iosettings = {}
    used_iobanks = set()

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

""".format(N=num_ports - 1)

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

            if drive is not None:
                params["DRIVE"] = int(drive)

            if slew is not None:
                params["SLEW"] = "\"{}\"".format(slew)

            iobank, pin = PINOUT[board]["single-ended"][index]
            used_iobanks.add(iobank)

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

            if num_ports > 1:
                pcf += "set_io ino[{}] {}\n".format(index, pin)
                pcf += "set_io led[{}] {}\n".format(
                    index, PINOUT[board]["led"][index]
                )
            else:
                pcf += "set_io ino {}\n".format(pin)
                pcf += "set_io led {}\n".format(PINOUT[board]["led"][index])

            iosettings[pin] = {k: unquote(v) for k, v in params.items()}
            index += 1

    # Footer
    verilog += """
endmodule
"""

    # VREF
    tcl = ""
    if vref is not None:
        for iobank in used_iobanks:
            tcl += "set_property INTERNAL_VREF {} [get_iobanks {}]\n".format(
                vref, iobank
            )

    return verilog, pcf, tcl, iosettings


# =============================================================================


def generate_diff_output(board, iostandard, drives, slews):
    """
    Generates a design which outputs 100Hz square wave to a number of pins
    in which each one has different DRIVE+SLEW setting. The IOSTANDARD is
    common for all of them.
    """

    num_ports = len(drives) * len(slews)
    iosettings = {}

    # Header
    verilog = """
module top(
    input  wire clk,
    output wire [{N}:0] out_p,
    output wire [{N}:0] out_n
);
""".format(N=num_ports - 1)

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

            if drive is not None:
                params["DRIVE"] = int(drive)

            if slew is not None:
                params["SLEW"] = "\"{}\"".format(slew)

            iobank, *pins = PINOUT[board]["differential"][index]

            verilog += """
    OBUFDS # ({params}) obuf_{index} (
    .I(tick),
    .O(out_p[{index}]),
    .OB(out_n[{index}])
    );
            """.format(
                params=",".join(
                    [".{}({})".format(k, v) for k, v in params.items()]
                ),
                index=index
            )

            if num_ports > 1:
                pcf += "set_io out_p[{}] {}\n".format(index, pins[0])
                pcf += "set_io out_n[{}] {}\n".format(index, pins[1])
            else:
                pcf += "set_io out_p {}\n".format(pins[0])
                pcf += "set_io out_n {}\n".format(pins[1])

            iosettings[pins[0]] = {k: unquote(v) for k, v in params.items()}
            iosettings[pins[1]] = {k: unquote(v) for k, v in params.items()}
            index += 1

    # Footer
    verilog += """
endmodule
"""

    return verilog, pcf, "", iosettings


def generate_diff_input(board, iostandard, in_terms, vref):
    """
    Generates a design with singnals from external pins go through IBUFs and
    registers to LEDs. Each IBUF has differen IN_TERM setting.
    """

    num_ports = len(in_terms)
    iosettings = {}
    used_iobanks = set()

    # Header
    verilog = """
module top(
    input  wire clk,
    input  wire [{N}:0] inp_p,
    input  wire [{N}:0] inp_n,
    output reg  [{N}:0] led
);

    initial led <= 0;
""".format(N=num_ports - 1)

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
        }

        if in_term is not None:
            params["IN_TERM"] = "\"{}\"".format(in_term)

        iobank, *pins = PINOUT[board]["differential"][index]
        used_iobanks.add(iobank)

        verilog += """
    wire inp_b[{index}];

    IBUFDS # ({params}) ibuf_{index} (
    .I(inp_p[{index}]),
    .IB(inp_n[{index}]),
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

        if num_ports > 1:
            pcf += "set_io inp_p[{}] {}\n".format(index, pins[0])
            pcf += "set_io inp_n[{}] {}\n".format(index, pins[1])
            pcf += "set_io led[{}] {}\n".format(
                index, PINOUT[board]["led"][index]
            )
        else:
            pcf += "set_io inp_p {}\n".format(pins[0])
            pcf += "set_io inp_n {}\n".format(pins[1])
            pcf += "set_io led {}\n".format(PINOUT[board]["led"][index])

        iosettings[pins[0]] = {k: unquote(v) for k, v in params.items()}
        iosettings[pins[1]] = {k: unquote(v) for k, v in params.items()}
        index += 1

    # Footer
    verilog += """
endmodule
"""

    # VREF
    tcl = ""
    if vref is not None:
        for iobank in used_iobanks:
            tcl += "set_property INTERNAL_VREF {} [get_iobanks {}]\n".format(
                vref, iobank
            )

    return verilog, pcf, tcl, iosettings


def generate_diff_inout(board, iostandard, drives, slews, vref):
    """
    Generates a design with INOUT buffers. Buffers cycle through states:
    L,Z,H,Z with 100Hz frequency. During the Z state, IO pins are latched
    and their state is presented on LEDs.
    """

    num_ports = len(drives) * len(slews)
    iosettings = {}
    used_iobanks = set()

    # Header
    verilog = """
module top(
    input  wire clk,
    inout  wire [{N}:0] ino_p,
    inout  wire [{N}:0] ino_n,
    output reg  [{N}:0] led
);

    initial led <= 0;

    wire [{N}:0] ino_i;
    reg ino_o;
    reg ino_t;

""".format(N=num_ports - 1)

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

            if drive is not None:
                params["DRIVE"] = int(drive)

            if slew is not None:
                params["SLEW"] = "\"{}\"".format(slew)

            iobank, *pins = PINOUT[board]["differential"][index]
            used_iobanks.add(iobank)

            verilog += """
    IOBUFDS # ({params}) iobuf_{index} (
    .I(ino_o),
    .O(ino_i[{index}]),
    .T(ino_t),
    .IO(ino_p[{index}]),
    .IOB(ino_n[{index}])
    );
            """.format(
                params=",".join(
                    [".{}({})".format(k, v) for k, v in params.items()]
                ),
                index=index
            )

            if num_ports > 1:
                pcf += "set_io ino_p[{}] {}\n".format(index, pins[0])
                pcf += "set_io ino_n[{}] {}\n".format(index, pins[1])
                pcf += "set_io led[{}] {}\n".format(
                    index, PINOUT[board]["led"][index]
                )
            else:
                pcf += "set_io ino_p {}\n".format(pins[0])
                pcf += "set_io ino_n {}\n".format(pins[1])
                pcf += "set_io led {}\n".format(PINOUT[board]["led"][index])

            iosettings[pins[0]] = {k: unquote(v) for k, v in params.items()}
            iosettings[pins[1]] = {k: unquote(v) for k, v in params.items()}
            index += 1

    # Footer
    verilog += """
endmodule
"""

    tcl = ""
    if vref is not None:
        for iobank in PINOUT[board]["iobanks"]:
            tcl += "set_property INTERNAL_VREF {} [get_iobanks {}]\n".format(
                vref, iobank
            )

    return verilog, pcf, tcl, iosettings


# =============================================================================


def main():

    # Parse arguments
    parser = argparse.ArgumentParser()
    parser.add_argument("--board", required=True, help="Board")
    parser.add_argument("--mode", required=True, help="Generation mode")
    parser.add_argument("--iostandard", required=True, help="IOSTANDARD")
    parser.add_argument(
        "--drive", required=False, nargs="+", default=[None], help="DRIVE(s)"
    )
    parser.add_argument(
        "--slew", required=False, nargs="+", default=[None], help="SLEW(s)"
    )
    parser.add_argument("--vref", required=False, default=None, help="VREF")
    parser.add_argument(
        "--in_term",
        required=False,
        nargs="+",
        default=[None],
        help="IN_TERM(s)"
    )
    parser.add_argument("-o", required=True, help="Design name")

    args = parser.parse_args()

    # Generate design for output IO settings
    if args.mode == "output":
        verilog, pcf, tcl, iosettings = generate_output(
            args.board, args.iostandard, args.drive, args.slew
        )
    elif args.mode == "input":
        verilog, pcf, tcl, iosettings = generate_input(
            args.board, args.iostandard, args.in_term, args.vref
        )
    elif args.mode == "inout":
        verilog, pcf, tcl, iosettings = generate_inout(
            args.board, args.iostandard, args.drive, args.slew, args.vref
        )
    elif args.mode == "diff_output":
        verilog, pcf, tcl, iosettings = generate_diff_output(
            args.board, args.iostandard, args.drive, args.slew
        )
    elif args.mode == "diff_input":
        verilog, pcf, tcl, iosettings = generate_diff_input(
            args.board, args.iostandard, args.in_term, args.vref
        )
    elif args.mode == "diff_inout":
        verilog, pcf, tcl, iosettings = generate_diff_inout(
            args.board, args.iostandard, args.drive, args.slew, args.vref
        )
    else:
        raise RuntimeError("Unknown generation mode '{}'".format(args.mode))

    # Write verilog
    with open(args.o + ".v", "w") as fp:
        fp.write(verilog)

    # Write PCF
    with open(args.o + ".pcf", "w") as fp:
        fp.write(pcf)

    # Write XDC
    with open(args.o + ".xdc", "w") as fp:
        fp.write(tcl)


if __name__ == "__main__":
    main()
