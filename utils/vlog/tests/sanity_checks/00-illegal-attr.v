(* blackbox *)
(* FASM_STUFF = "fasm stuff" *)
module top (I0, I1, O);

 input  wire I0;
 input  wire I1;
 output wire O;

 assign O = I0 | I1;

endmodule

