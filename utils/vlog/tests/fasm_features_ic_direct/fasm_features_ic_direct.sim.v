`include "../common/and_gate.sim.v"
`include "../common/xor_gate.sim.v"

module fasm_features_ic_direct (I0, I1, O0, O1, O2, O3);
  input  wire I0;
  input  wire I1;
(* FASM_MUX = "out0_fasm_mux" *)
  output wire O0;
(* FASM_MUX = "out1_fasm_mux" *)
  output wire O1;
(* FASM_MUX = "out2_fasm_mux" *)
  output wire O2;
  output wire O3;

 and_gate gate1(I0, I1, O0);
 xor_gate gate2(I0, I1, O1);

 assign O2 = I0;
 assign O3 = I1;

endmodule

