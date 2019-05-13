`include "../common/and_gate.sim.v"

(* FASM_FEATURES = "MY_FASM_FEATURE_A MY_FASM_FEATURE_B" *)
module fasm_features (I0, I1, O);
  input  wire I0;
  input  wire I1;
  output wire O;

 and_gate gate1 (I0, I1, O);

endmodule

