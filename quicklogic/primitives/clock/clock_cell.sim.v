(* whitebox *)
module CLOCK_CELL(I_PAD, O_CLK);

//    (* CLOCK *)
    input  wire I_PAD;

    (* CLOCK=0 *)
    (* DELAY_CONST_I_PAD="{iopath_IP_IC}" *)
    output wire O_CLK;

    assign O_CLK = I_PAD;

endmodule
