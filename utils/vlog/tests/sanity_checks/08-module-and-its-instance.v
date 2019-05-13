`include "../common/nand_gate.sim.v"

module top (I0, I1, O);
  input  wire I0;
  input  wire I1;
  output wire O;

 (* FASM_FEATURES = "ANOTHER_FASM_FEATURE" *)
 nand_gate gate (I0, I1, O);

endmodule

