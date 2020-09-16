`timescale 1ns/10ps
(* whitebox *)
(* FASM_FEATURES="INTERFACE.ASSP.INV.ASSPInvPortAlias" *)
module CLOCK_CELL(I_PAD, O_CLK);

    (* iopad_external_pin *)
    (* CLOCK, NO_COMB=0 *)
    input  wire I_PAD;

    (* CLOCK=0 *)
    (* DELAY_CONST_I_PAD="{iopath_IP_IC}" *)
    output wire O_CLK;
	
	specify
        (I_PAD=>O_CLK)=(0,0);
    endspecify

    assign O_CLK = I_PAD;

endmodule
