(* whitebox *)
module BIDIR_IBUF(P, O, E);

    input  wire P;  // Data signal from the PAD
    input  wire E;  // Input enable signal

    (* DELAY_CONST_P="10e-11" *)
    (* DELAY_CONST_E="10e-11" *)
    output wire O;  // Data output after the enable gate

    assign O = (E == 1'b1) ? P : 1'b0;

endmodule
