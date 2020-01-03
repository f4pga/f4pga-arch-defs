(* whitebox *)
module NOT (I, O);

  input  wire I;
  (* DELAY_CONST_I="1e-10" *)
  output wire O;

  assign O = ~I;

endmodule
