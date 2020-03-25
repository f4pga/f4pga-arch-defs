(* whitebox *)
module CLOCK_IOBUF(I_PAD, O_CLK);
    input  wire I_PAD;

    (* DELAY_CONST_I_PAD="{iopath_IP_IC}" *)
    output wire O_CLK;

    assign O_CLK = I_PAD;

endmodule
