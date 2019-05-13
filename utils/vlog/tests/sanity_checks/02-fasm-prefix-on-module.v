`include "../common/and_gate.sim.v"

(* FASM_PREFIX = "prefix" *)
module top (I0, I1, O);

 input  wire I0;
 input  wire I1;
 output wire O;

 and_gate gate (I0, I1, O);

endmodule

