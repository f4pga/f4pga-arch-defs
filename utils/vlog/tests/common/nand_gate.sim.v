(* blackbox *)
(* FASM_FEATURES="NAND_GATE_INCLUDED_FASM_FEATURES" *)
module nand_gate(I0, I1, O);
  input  wire I0;
  input  wire I1;
  output wire O;

 assign O = ~(I0 & I1);

endmodule
