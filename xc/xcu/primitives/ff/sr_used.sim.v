(* whitebox *)
module SR_USED(SR, SR_OUT);
    input wire SR;

    (* DELAY_CONST_SR="1e-10" *)
    output wire SR_OUT;

    assign SR_OUT = SR;
endmodule
