`include "../vpr_pad/vpr_ipad.sim.v"
`include "../vpr_pad/vpr_opad.sim.v"
`include "./bidir_iobuf.sim.v"

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

    (* pack="IPAD_TO_IBUF" *)
    wire i_pad;
    wire i_dat;
    wire i_en;

    (* pack="OBUF_TO_OPAD" *)
    wire o_pad;
    wire o_dat;
    wire o_en;

    // Input or inout mode
    generate if (MODE == "INPUT" || MODE == "INOUT") begin

        (* keep *)
        VPR_IPAD inpad(i_pad);

        // TODO: Add FF here

    // Output or inout mode
    end else if (MODE == "OUTPUT" || MODE == "INOUT") begin

        (* keep *)
        VPR_OPAD outpad(o_pad);

        // TODO: Add FFs and routing MUXes here

    end endgenerate

    assign IZ    = i_dat;
    assign i_en  = INEN;
    assign o_en  = IE;
    assign o_dat = OQI;

    // IO buffer
    generate if (MODE == "INPUT") begin

        (* keep *)
        (* FASM_PREFIX="INTERFACE.BIDIR" *)
        BIDIR_IOBUF bidir_buf(
            .I_PAD(i_pad),
            .I_DAT(i_dat),
            .I_EN (i_en),
            .O_PAD(),
            .O_DAT(o_dat),
            .O_EN (o_en)
        );

    end else if (MODE == "OUTPUT") begin
    
        (* keep *)
        (* FASM_PREFIX="INTERFACE.BIDIR" *)
        BIDIR_IOBUF bidir_buf(
            .I_PAD(),
            .I_DAT(i_dat),
            .I_EN (i_en),
            .O_PAD(o_pad),
            .O_DAT(o_dat),
            .O_EN (o_en)
        );

    end else if (MODE == "INOUT") begin
    
        (* keep *)
        (* FASM_PREFIX="INTERFACE.BIDIR" *)
        BIDIR_IOBUF bidir_buf(
            .I_PAD(i_pad),
            .I_DAT(i_dat),
            .I_EN (i_en),
            .O_PAD(o_pad),
            .O_DAT(o_dat),
            .O_EN (o_en)
        );

    end endgenerate

endmodule
