`timescale 1ns/10ps
(* whitebox *)
module SDIOMUX_CELL(
    I_PAD_$inp, I_DAT, I_EN,
    O_PAD_$out, O_DAT, O_EN
);
    (* iopad_external_pin *)
    input  wire I_PAD_$inp;
    input  wire I_EN;

    input  wire O_DAT;
    input  wire O_EN;

    (* DELAY_CONST_I_PAD_$inp="{iopath_IP_IZ}" *)
    (* DELAY_CONST_I_EN="{iopath_FBIO_In_En0_FBIO_In0}" *)
    output wire I_DAT;

    (* DELAY_CONST_O_DAT="{iopath_OQI_IP}" *)
    (* DELAY_CONST_O_EN="{iopath_OE_IP}" *)
    (* iopad_external_pin *)
    output wire O_PAD_$out;
	
    specify
        (O_DAT => O_PAD_$out) = (0,0);
        (O_EN => O_PAD_$out) = (0,0);
        (I_PAD_$inp => I_DAT) = (0,0);
        (I_EN => I_DAT) = (0,0);
    endspecify

    // Behavioral model
    assign I_DAT = (I_EN == 1'b0) ? I_PAD_$inp : 1'b0;
    assign O_PAD_$out = (O_EN == 1'b0) ? O_DAT : 1'b0;

endmodule
