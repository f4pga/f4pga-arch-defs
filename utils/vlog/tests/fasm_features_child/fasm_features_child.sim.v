`include "../common/and_gate.sim.v"
`include "../common/xor_gate.sim.v"
`include "../common/nand_gate.sim.v"

(* FASM_PREFIX = "TOP_FASM_PREFIX" *)
module fasm_features_child (I0, I1, O0, O1, O2);
  input  wire I0;
  input  wire I1;
  output wire O0;
  output wire O1;
  output wire O2;

 (* FASM_PREFIX = "THIS_IS_THE_AND_GATE" *)
 and_gate gate1(I0, I1, O0);

 (* FASM_FEATURES = "FEATURE_A FEATURE_B" *)
 xor_gate gate2(I0, I1, O1);

 (* FASM_PREFIX = "THIS_IS_THE_NAND_GATE" *)
 (* FASM_FEATURES = "FEATURE_C FEATURE_D" *)
 nand_gate gate3(I0, I1, O2);

endmodule

