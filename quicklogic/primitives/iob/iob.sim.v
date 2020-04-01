`include "../vpr_pad/vpr_ipad.sim.v"
`include "../vpr_pad/vpr_opad.sim.v"
`include "./iobuf.sim.v"

(* MODES="INPUT;OUTPUT;INOUT" *)
module IOB(
    output wire ID,
    input  wire IE,
    input  wire OD,
    input  wire OE
);

    parameter MODE = "INPUT";

    // Input mode
    generate if (MODE == "INPUT") begin

        (* pack="IPAD_TO_IBUF" *)
        wire i_pad;

        (* keep *)
        VPR_IPAD inpad(i_pad);

    // Output mode
    end else if (MODE == "OUTPUT") begin

        (* pack="OBUF_TO_OPAD" *)
        wire o_pad;

        (* keep *)
        VPR_OPAD outpad(o_pad);

    // InOut mode
    end if (MODE == "INOUT") begin

        (* pack="IOPAD_TO_IOBUF" *)
        wire i_pad;

        (* pack="IOPAD_TO_IOBUF" *)
        wire o_pad;

        (* keep *)
        VPR_IPAD inpad(i_pad);

        (* keep *)
        VPR_OPAD outpad(o_pad);

    end endgenerate

    // IO buffer
    generate if (MODE == "INPUT") begin

        (* keep *)
        (* FASM_PREFIX="INTERFACE.BIDIR" *)
        IOBUF iob(
            .I_PAD_$inp(i_pad),
            .I_DAT(ID),
            .I_EN (IE),
            .O_PAD_$out(),
            .O_DAT(OD),
            .O_EN (OE)
        );

    end else if (MODE == "OUTPUT") begin

        (* keep *)
        (* FASM_PREFIX="INTERFACE.BIDIR" *)
        IOBUF iob(
            .I_PAD_$inp(),
            .I_DAT(ID),
            .I_EN (IE),
            .O_PAD_$out(o_pad),
            .O_DAT(OD),
            .O_EN (OE)
        );

    end else if (MODE == "INOUT") begin

        (* keep *)
        (* FASM_PREFIX="INTERFACE.BIDIR" *)
        IOBUF iob(
            .I_PAD_$inp(i_pad),
            .I_DAT(ID),
            .I_EN (IE),
            .O_PAD_$out(o_pad),
            .O_DAT(OD),
            .O_EN (OE)
        );

    end endgenerate

endmodule
