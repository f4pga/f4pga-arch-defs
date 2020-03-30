`include "../vpr_pad/vpr_ipad.sim.v"
`include "../vpr_pad/vpr_opad.sim.v"
`include "../iob/iob.sim.v"

(* MODES="INPUT;OUTPUT;INOUT" *)
module SDIOMUX(
    input  wire IE,
    input  wire OQI,
    input  wire OE,
    output wire IZ
);

    parameter MODE = "INPUT";

    (* pack="IPAD_TO_IBUF" *)
    wire i_pad;

    (* pack="OBUF_TO_OPAD" *)
    wire o_pad;

    // Input or inout mode
    generate if (MODE == "INPUT" || MODE == "INOUT") begin

        (* keep *)
        VPR_IPAD inpad(i_pad);

    // Output or inout mode
    end else if (MODE == "OUTPUT" || MODE == "INOUT") begin

        (* keep *)
        VPR_OPAD outpad(o_pad);

    end endgenerate


    // IO buffer
    generate if (MODE == "INPUT") begin

        (* keep *)
        IOB iob(
            .I_PAD(i_pad),
            .I_DAT(IZ),
            .I_EN (IE),
            .O_PAD(),
            .O_DAT(),
            .O_EN ()
        );

    end else if (MODE == "OUTPUT") begin
    
        (* keep *)
        IOB iob(
            .I_PAD(),
            .I_DAT(),
            .I_EN (),
            .O_PAD(o_pad),
            .O_DAT(OQI),
            .O_EN (OE)
        );

    end else if (MODE == "INOUT") begin
    
        (* keep *)
        IOB iob(
            .I_PAD(i_pad),
            .I_DAT(IZ),
            .I_EN (IE),
            .O_PAD(o_pad),
            .O_DAT(OQI),
            .O_EN (OE)
        );

    end endgenerate

endmodule
