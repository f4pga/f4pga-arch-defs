(* whitebox *)
module BIDIR_OBUF(P, I, E);

    input  wire I;  // Data input
    input  wire E;  // Enable input

    (* DELAY_CONST_I="10e-11" *) 
    (* DELAY_CONST_E="10e-11" *) 
    output wire P;  // To pad

    assign P = (E == 1'b1) ? I : 1'bz;

endmodule
