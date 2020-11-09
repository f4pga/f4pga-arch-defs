`include "../vpr_pad/vpr_ipad.sim.v"
`include "../vpr_pad/vpr_opad.sim.v"
`include "./bidir_cell.sim.v"

(* MODES="INPUT;OUTPUT;INOUT" *)
module BIDIR(
    input  wire IE,
    (* CLOCK *)
    (* clkbuf_sink *)
    input  wire IQC,
    input  wire OQI,
    input  wire OQE,
    input  wire IQE,
    input  wire IQR,
    input  wire INEN,
    input  wire IQIN,
    output wire IZ,
    output wire IQZ
);

    parameter MODE = "INPUT";

    // Input mode
    generate if (MODE == "INPUT") begin

        (* pack="IPAD_TO_BIDIR" *)
        wire i_pad;

        (* keep *)
        VPR_IPAD inpad(i_pad);

    // Output mode
    end else if (MODE == "OUTPUT") begin

        (* pack="BIDIR_TO_OPAD" *)
        wire o_pad;

        (* keep *)
        VPR_OPAD outpad(o_pad);

    // InOut mode
    end if (MODE == "INOUT") begin

        (* pack="IOPAD_TO_BIDIR" *)
        wire i_pad;

        (* pack="IOPAD_TO_BIDIR" *)
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
        BIDIR_CELL bidir(
            .I_PAD_$inp(i_pad),
            .I_DAT(IZ),
            .I_EN (INEN),
            .O_PAD_$out(),
            .O_DAT(OQI),
            .O_EN (IE)
        );

    end else if (MODE == "OUTPUT") begin

        (* keep *)
        (* FASM_PREFIX="INTERFACE.BIDIR" *)
        BIDIR_CELL bidir(
            .I_PAD_$inp(),
            .I_DAT(IZ),
            .I_EN (INEN),
            .O_PAD_$out(o_pad),
            .O_DAT(OQI),
            .O_EN (IE)
        );

    end else if (MODE == "INOUT") begin

        (* keep *)
        (* FASM_PREFIX="INTERFACE.BIDIR" *)
        BIDIR_CELL bidir(
            .I_PAD_$inp(i_pad),
            .I_DAT(IZ),
            .I_EN (INEN),
            .O_PAD_$out(o_pad),
            .O_DAT(OQI),
            .O_EN (IE)
        );

    end endgenerate

endmodule
