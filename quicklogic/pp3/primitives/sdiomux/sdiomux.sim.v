`include "../vpr_pad/vpr_ipad.sim.v"
`include "../vpr_pad/vpr_opad.sim.v"
`include "./sdiomux_cell.sim.v"

(* MODES="INPUT;OUTPUT;INOUT" *)
module SDIOMUX(
    input  wire OQI,
    input  wire IE,
    input  wire OE,
    output wire IZ,
);

    parameter MODE = "INPUT";

    // Input mode
    generate if (MODE == "INPUT") begin

        (* pack="IPAD_TO_SDIOMUX" *)
        wire i_pad;

        (* keep *)
        VPR_IPAD inpad(i_pad);

    // Output mode
    end else if (MODE == "OUTPUT") begin

        (* pack="SDIOMUX_TO_OPAD" *)
        wire o_pad;

        (* keep *)
        VPR_OPAD outpad(o_pad);

    // InOut mode
    end if (MODE == "INOUT") begin

        (* pack="IOPAD_TO_SDIOMUX" *)
        wire i_pad;

        (* pack="IOPAD_TO_SDIOMUX" *)
        wire o_pad;

        (* keep *)
        VPR_IPAD inpad(i_pad);

        (* keep *)
        VPR_OPAD outpad(o_pad);

    end endgenerate

    // IO buffer
    generate if (MODE == "INPUT") begin

        (* keep *)
        SDIOMUX_CELL sdiomux(
            .I_PAD_$inp(i_pad),
            .I_DAT(IZ),
            .I_EN (IE),
            .O_PAD_$out(),
            .O_DAT(OQI),
            .O_EN (OE)
        );

    end else if (MODE == "OUTPUT") begin

        (* keep *)
        SDIOMUX_CELL sdiomux(
            .I_PAD_$inp(),
            .I_DAT(IZ),
            .I_EN (IE),
            .O_PAD_$out(o_pad),
            .O_DAT(OQI),
            .O_EN (OE)
        );

    end else if (MODE == "INOUT") begin

        (* keep *)
        SDIOMUX_CELL sdiomux(
            .I_PAD_$inp(i_pad),
            .I_DAT(IZ),
            .I_EN (IE),
            .O_PAD_$out(o_pad),
            .O_DAT(OQI),
            .O_EN (OE)
        );

    end endgenerate

endmodule
