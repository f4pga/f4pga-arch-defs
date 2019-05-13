`include "../common/and_gate.sim.v"

(* MODES = "AND;XOR" *)
(* FASM_PARAMS_AND = "params_and" *)
(* FASM_PARAMS_XOR = "params_xor" *)
(* FASM_STUFF_AND = "stuff_and" *)
module top (I0, I1, O);

 input  wire I0;
 input  wire I1;
 output wire O;

 parameter MODE = "AND";

 and_gate gate (I0, I1, O);

endmodule

