(* whitebox *)
module CE_USED(CE, CE_OUT);
    input wire CE;

    (* DELAY_CONST_CE="1e-10" *)
    output wire CE_OUT;

    assign CE_OUT = CE;
endmodule
