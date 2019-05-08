`include "../common/and_gate.sim.v"
`include "../common/xor_gate.sim.v"

module fasm_features_array (I0, I1, O0, O1, O2, O3, O4);
  input  wire I0;
  input  wire I1;

  output wire O0;
  output wire O1;
  output wire O2;
  output wire O3;
  output wire O4;

 (* FASM_PREFIX = "GATE_A" *)
 and_gate gate_a(I0, I1, O0);
 (* FASM_PREFIX = "GATE_B" *)
 and_gate gate_b(I0, I1, O1);
 (* FASM_PREFIX = "GATE_C" *)
 and_gate gate_c(I0, I1, O2);
 (* FASM_PREFIX = "GATE_D" *)
 and_gate gate_d(I0, I1, O3);

 (* FASM_PREFIX = "XOR_GATE" *)
 xor_gate gate_x(I0, I1, O4);

endmodule

