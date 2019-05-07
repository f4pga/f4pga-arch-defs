`include "../common/and_gate.sim.v"
`include "../common/xor_gate.sim.v"

module fasm_features_ic_direct (
  input  INP0,
  input  INP1,
  output OUT0,
  output OUT1,
  output OUT2,
  output OUT3
);

wire INP0;
wire INP1;

(* FASM_MUX = "out0_fasm_mux" *)
wire OUT0;
(* FASM_MUX = "out1_fasm_mux" *)
wire OUT1;
(* FASM_MUX = "out2_fasm_mux" *)
wire OUT2;

wire OUT3;

and_gate gate1(INP0, INP1, OUT0);
xor_gate gate2(INP0, INP1, OUT1);

assign OUT2 = INP0;
assign OUT3 = INP1;

endmodule

