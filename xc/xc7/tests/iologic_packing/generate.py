#!/usr/bin/env python3
"""
The generator
"""
import argparse

# =============================================================================

# This is a "fake" pinout. It is not intended to work on any HW, just for the
# toolchain verification.
PINOUT = {
    "arty-full":
        {
            "clocks": [
                "E3",
                "F4",  # This one is fake
            ],
            "generic":
                [
                    # All these are fake
                    "C6",
                    "C5",
                    "B7",
                    "B6",
                    "A6",
                    "A5",
                    "D8",
                    "C7",
                ],
            "single-ended": [
                # Bank 15
                "J17",
                "J18",
                "K15",
                "J15",
            ],
            "differential": [
                # Bank 15
                ("E15", "E16"),
                ("D15", "C15"),
            ],
            "idelayctrl": "IDELAYCTRL_X0Y1"
        },
    "basys3-bottom":
        {
            "clocks": [
                "M18",
                "L17",
            ],
            "generic":
                [
                    "N17",
                    "P17",
                    "P18",
                    "R18",
                    "U19",
                    "V19",
                    "W18",
                    "W19",
                ],
            "single-ended": [
                "V2",
                "W2",
                "V3",
                "W3",
            ],
            "differential": [
                ("V2", "W2"),
                ("V3", "W3"),
            ],
            "idelayctrl": "IDELAYCTRL_X0Y0",
        },
}

# =============================================================================

INPUT_IOBS = frozenset((
    "IBUF",
    "IBUFDS",
))
OUTPUT_IOBS = frozenset((
    "OBUF",
    "OBUFT",
    "OBUFDS",
    "OBUFTDS",
))
INOUT_IOBS = frozenset((
    "IOBUF",
    "IOBUFDS",
))

TRISTATE_IOBS = frozenset((
    "OBUFT",
    "IOBUF",
    "OBUFTDS",
    "IOBUFDS",
))
DIFF_IOBS = frozenset((
    "IBUFDS",
    "OBUFDS",
    "OBUFTDS",
    "IOBUFDS",
))

VALID_IOBS = INPUT_IOBS | OUTPUT_IOBS | INOUT_IOBS

# =============================================================================


def make_header(board, iob_type, use_idelay, use_iserdes, use_oserdes):

    ck_pads = iter(PINOUT[board]["clocks"])
    ge_pads = iter(PINOUT[board]["generic"])
    se_pads = iter(PINOUT[board]["single-ended"])
    df_pads = iter(PINOUT[board]["differential"])

    inp_ports = []
    out_ports = []
    ino_ports = []

    verilog = ""
    pcf = ""
    xdc = ""

    # Single-ended IOB
    if iob_type not in DIFF_IOBS:
        if iob_type in INPUT_IOBS:
            inp_ports.append("pad")
        elif iob_type in OUTPUT_IOBS:
            out_ports.append("pad")
        elif iob_type in INOUT_IOBS:
            ino_ports.append("pad")

        # LOC
        pad = next(se_pads)
        pcf += "set_io pad {}\n".format(pad)

    # Differential IOB
    else:
        if iob_type in INPUT_IOBS:
            inp_ports.extend(["pad_p", "pad_n"])
        elif iob_type in OUTPUT_IOBS:
            out_ports.extend(["pad_p", "pad_n"])
        elif iob_type in INOUT_IOBS:
            ino_ports.extend(["pad_p", "pad_n"])

        # LOC
        pads = next(df_pads)
        pcf += "set_io pad_p {}\n".format(pads[0])
        pcf += "set_io pad_n {}\n".format(pads[1])

        # IO standard
        xdc += "set_property IOSTANDARD DIFF_SSTL135 [get_ports pad_p]\n"
        xdc += "set_property IOSTANDARD DIFF_SSTL135 [get_ports pad_n]\n"

    # Clock
    if use_iserdes or use_oserdes or use_idelay:
        inp_ports.append("clk")

        pad = next(ck_pads)
        pcf += "set_io clk {}\n".format(pad)

        if use_iserdes or use_oserdes:
            inp_ports.append("clkdiv")

            pad = next(ck_pads)
            pcf += "set_io clkdiv {}\n".format(pad)

    # Out
    if iob_type in INPUT_IOBS or iob_type in INOUT_IOBS:
        out_ports.append("out")

        # LOC
        pad = next(ge_pads)
        pcf += "set_io out {}\n".format(pad)

    # Tristate control
    if iob_type in TRISTATE_IOBS:
        inp_ports.append("oen")

        # LOC
        pad = next(ge_pads)
        pcf += "set_io oen {}\n".format(pad)

    # In
    if iob_type in OUTPUT_IOBS or iob_type in INOUT_IOBS:
        inp_ports.append("inp")

        # LOC
        pad = next(ge_pads)
        pcf += "set_io inp {}\n".format(pad)

    # IDELAYCTRL RDY out
    if use_idelay:
        out_ports.append("rdy")

        # LOC
        pad = next(ge_pads)
        pcf += "set_io rdy {}\n".format(pad)

    # IOSTANDARD
    for port in (*inp_ports, *out_ports, *ino_ports):
        if "_p" not in port and "_n" not in port:
            xdc += "set_property IOSTANDARD LVCMOS33 [get_ports {}]\n".format(
                port
            )

    # Make the Verilog header
    verilog += "module top (\n"

    for port in inp_ports:
        verilog += "    input  wire {},\n".format(port)
    for port in out_ports:
        verilog += "    output wire {},\n".format(port)
    for port in ino_ports:
        verilog += "    inout  wire {},\n".format(port)
    verilog = verilog[:-2] + "\n"

    verilog += ");\n"

    # If there is a clock add a BUFG
    for clk in ["clk", "clkdiv"]:
        if clk in inp_ports:
            verilog += """
    wire {clk}_bufg;
    BUFG bufg_{clk} (.I({clk}), .O({clk}_bufg));
            """.format(clk=clk)

    return verilog, pcf, xdc


def make_iob(iob_type):

    verilog = """
    wire iob_i; // From IOB
    wire iob_o; // To IOB
    wire iob_t;
"""

    # Instantiate the IOB
    if iob_type == "IBUF":

        verilog += """
    IBUF iob (
        .I(pad),
        .O(iob_i)
    );
"""

    elif iob_type == "OBUF":

        verilog += """
    OBUF iob (
        .I(iob_o),
        .O(pad)
    );
"""

    elif iob_type == "OBUFT":

        verilog += """
    OBUFT iob (
        .I(iob_o),
        .T(iob_t),
        .O(pad)
    );
"""

    elif iob_type == "IOBUF":

        verilog += """
    IOBUF iob (
        .I(iob_o),
        .T(iob_t),
        .O(iob_i),
        .IO(pad)
    );
"""

    elif iob_type == "IBUFDS":

        verilog += """
    IBUFDS iob (
        .I(pad_p),
        .IB(pad_n),
        .O(iob_i)
    );
"""

    elif iob_type == "OBUFDS":

        verilog += """
    OBUFDS iob (
        .I(iob_o),
        .O(pad_p),
        .OB(pad_n)
    );
"""

    elif iob_type == "OBUFTDS":

        verilog += """
    OBUFTDS iob (
        .I(iob_o),
        .T(iob_t),
        .O(pad_p),
        .OB(pad_n)
    );
"""

    elif iob_type == "IOBUFDS":

        verilog += """
    IOBUFDS iob (
        .I(iob_o),
        .T(iob_t),
        .O(iob_i),
        .IO(pad_p),
        .IOB(pad_n)
    );
"""

    else:
        raise RuntimeError("Unsupported IOB type '{}'".format(iob_type))

    return verilog


def make_idelay(board, use_idelay):

    if use_idelay:
        loc = PINOUT[board]["idelayctrl"]

        return """
    wire dly_i;

    IDELAYE2 #(
        .DELAY_SRC      ("IDATAIN"),
        .IDELAY_TYPE    ("FIXED"),
        .IDELAY_VALUE   (16)
    ) idelay (
        .IDATAIN        (iob_i),
        .DATAOUT        (dly_i)
    );

    (* LOC="{}" *)
    IDELAYCTRL idelayctrl (
        .REFCLK         (clk_bufg),
        .RDY            (rdy)
    );
        """.format(loc)

    else:
        return """
    wire dly_i = iob_i;
"""


def make_iserdes(use_idelay, use_iserdes):

    if use_iserdes:

        if use_idelay:
            return """
    wire dat_i;

    ISERDESE2 #(
        .IOBDELAY("BOTH"),
        .DATA_RATE("SDR"),
        .DATA_WIDTH(4'd2),
        .INTERFACE_TYPE("NETWORKING")
    ) iserdes (
        .DDLY(dly_i),
        .Q1(dat_i),
        .CLK(clk_bufg),
        .CLKB(~clk_bufg),
        .CLKDIV(clkdiv_bufg)
    );
"""
        else:
            return """
    wire dat_i;

    ISERDESE2 #(
        .IOBDELAY("NONE"),
        .DATA_RATE("SDR"),
        .DATA_WIDTH(4'd2),
        .INTERFACE_TYPE("NETWORKING")
    ) iserdes (
        .D(dly_i),
        .Q1(dat_i),
        .CLK(clk_bufg),
        .CLKB(~clk_bufg),
        .CLKDIV(clkdiv_bufg)
    );
"""

    else:
        return """
    wire dat_i = dly_i;
"""


def make_oserdes(use_oserdes):

    if use_oserdes:
        return """
    wire dat_o;
    wire dat_t;

    OSERDESE2 #(
        .DATA_RATE_OQ("SDR"),
        .DATA_RATE_TQ("SDR"),
        .DATA_WIDTH(2),
        .TRISTATE_WIDTH(1)
    ) oserdes (
        .OQ(iob_o),
        .TQ(iob_t),
        .D1(dat_o),
        .T1(dat_t),
        .CLK(clk_bufg),
        .CLKDIV(clkdiv_bufg)
    );
"""

    else:
        return """
    wire dat_o;
    wire dat_t;

    assign iob_o = dat_o;
    assign iob_t = dat_t;
"""


# =============================================================================


def main():

    # Parse arguments
    parser = argparse.ArgumentParser()

    parser.add_argument("-o", required=True, help="Output design name")
    parser.add_argument("--board", required=True, help="Board")
    parser.add_argument("--iob", required=True, help="IOB cell type to use")
    parser.add_argument("--iserdes", action="store_true", help="Use ISERDES")
    parser.add_argument("--idelay", action="store_true", help="Use IDELAY")
    parser.add_argument("--oserdes", action="store_true", help="Use OSERDES")

    args = parser.parse_args()

    # Check args
    if args.idelay and args.iob not in INPUT_IOBS and args.iob not in INOUT_IOBS:
        raise RuntimeError("Cannot have {} and IDELAY".format(args.iob))

    if args.iserdes and args.iob not in INPUT_IOBS and args.iob not in INOUT_IOBS:
        raise RuntimeError("Cannot have {} and ISERDES".format(args.iob))

    if args.oserdes and args.iob not in OUTPUT_IOBS and args.iob not in INOUT_IOBS:
        raise RuntimeError("Cannot have {} and OSERDES".format(args.iob))

    # Verilog header
    verilog, pcf, xdc = make_header(
        args.board, args.iob, args.idelay, args.iserdes, args.oserdes
    )

    # IOB
    verilog += make_iob(args.iob)

    # IDELAY
    verilog += make_idelay(args.board, args.idelay)

    # ISERDES
    verilog += make_iserdes(args.idelay, args.iserdes)

    # OSERDES
    verilog += make_oserdes(args.oserdes)

    # Final connections
    if args.iob in INPUT_IOBS or args.iob in INOUT_IOBS:
        verilog += "    assign out = dat_i;\n"
    if args.iob in OUTPUT_IOBS or args.iob in INOUT_IOBS:
        verilog += "    assign dat_o = inp;\n"
    if args.iob in TRISTATE_IOBS:
        verilog += "    assign dat_t = oen;\n"

    # Verilog footer
    verilog += "endmodule\n"

    # Write verilog
    with open(args.o + ".v", "w") as fp:
        fp.write(verilog)

    # Write PCF
    with open(args.o + ".pcf", "w") as fp:
        fp.write(pcf)

    # Write XDC
    with open(args.o + ".xdc", "w") as fp:
        fp.write(xdc)


if __name__ == "__main__":
    main()
