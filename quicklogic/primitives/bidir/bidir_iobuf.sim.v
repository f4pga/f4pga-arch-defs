(* whitebox *)
module BIDIR_IOBUF(
    I_PAD, I_DAT, I_EN,
    O_PAD, O_DAT, O_EN
);
    input  wire I_PAD;
    input  wire I_EN;

    input  wire O_DAT;
    input  wire O_EN;

    (* DELAY_CONST_I_PAD="10e-11" *)
    (* DELAY_CONST_I_EN="10e-11" *)
    output wire I_DAT;

    (* DELAY_CONST_O_DAT="10e-11" *)
    (* DELAY_CONST_O_EN="10e-11" *)
    output wire O_PAD;

    assign I_DAT = (I_EN == 1'b1) ? I_PAD : 1'b0;
    assign O_PAD = (O_EN == 1'b1) ? O_DAT : 1'b0;

endmodule
