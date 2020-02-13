`include "../vpr_pad/vpr_ipad.sim.v"
`include "../vpr_pad/vpr_opad.sim.v"
//`include "../inv/inv.sim.v"
`include "./bidir_ibuf.sim.v"
`include "./bidir_obuf.sim.v"

(* MODES="INPUT;OUTPUT;INOUT" *)
module BIDIR(
    input  wire IE,
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

    // TODO: Clock inverter
    wire clk = IQC;

    // Input or inout mode
    generate if (MODE == "INPUT" || MODE == "INOUT") begin
        (* pack="IPAD_TO_IBUF" *)
        wire i_pad;
        wire i_dat;
        wire i_en;

        // The PAD
        (* keep *)
        VPR_IPAD ipad(i_pad);

        // The IBUF
        (* keep *)
        BIDIR_IBUF ibuf(
        .P  (i_pad),
        .O  (i_dat),
        .E  (i_en)
        );

        assign IZ   = i_dat;
        assign i_en = INEN;

        // TODO: Add FF here

    end endgenerate

    // Output or inout mode
    generate if (MODE == "OUTPUT" || MODE == "OUTPUT") begin
        (* pack="OBUF_TO_OPAD" *)
        wire o_pad;
        wire o_dat;
        wire o_en;

        // TODO: Add FFs and routing MUXes here
        assign o_en  = IE;
        assign o_dat = OQI;

        // The OBUF
        (* keep *)
        BIDIR_OBUF obuf(
        .P  (o_pad),
        .I  (o_dat),
        .E  (o_en)
        );

        // the PAD
        (* keep *)
        VPR_OPAD opad(o_pad);

    end endgenerate

endmodule
