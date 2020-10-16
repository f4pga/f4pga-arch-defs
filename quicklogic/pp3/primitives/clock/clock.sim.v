`include "../vpr_pad/vpr_ipad.sim.v"
`include "./clock_cell.sim.v"

module CLOCK(
    output wire IC,
    output wire OP
);

    (* pack="IPAD_TO_CBUF" *)
    wire i_pad;

    // The VPR input pad
    (* keep *)
    VPR_IPAD inpad(i_pad);

    // IO buffer (the actual CLOCK cell counterpart)
    (* keep *)
    CLOCK_CELL clock_buf(
        .I_PAD(i_pad),
        .O_CLK(IC),
    );

endmodule
