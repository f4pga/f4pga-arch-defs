`include "../common/and_gate.sim.v"
`include "../common/xor_gate.sim.v"

(* FASM_FEATURES = "COMMON_FASM_FEATURES_FOR_ALL_MODES" *)
(* FASM_PREFIX_AND = "TOP_FASM_PREFIX_FOR_AND" *)
(* FASM_PREFIX_XOR = "TOP_FASM_PREFIX_FOR_XOR" *)
(* MODES = "AND; XOR" *)
module fasm_features_modes (I0, I1, O);
  input  wire I0;
  input  wire I1;
  output wire O;

  parameter MODE = "AND";

 generate
     if (MODE == "AND") begin
         (* FASM_PREFIX = "THIS_IS_THE_AND_GATE" *)
         and_gate gate(I0, I1, O);
     end else if (MODE == "XOR") begin
         (* FASM_FEATURES = "THIS_IS_THE_XOR_GATE" *)
         xor_gate gate(I0, I1, O);
     end
 endgenerate

endmodule

