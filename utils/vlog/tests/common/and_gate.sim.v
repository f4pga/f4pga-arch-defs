(* blackbox *)
module and_gate(
  input  wire I0,
  input  wire I1,
  output wire O
);

assign O = I0 & I1;

endmodule
