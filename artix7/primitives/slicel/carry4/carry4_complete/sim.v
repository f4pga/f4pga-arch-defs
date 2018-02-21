`include "carry4/sim.v"
// A wrapper is needed for the mode, so that we have sub pb-type with the
// correct name (CARRY4) inside the mode.

(* ALTERNATIVE_TO="CARRY4_TOP" *)
module CARRY4_COMPLETE(CO, O, CIN, DI, S);

output [3:0] CO;
output [3:0] O;

input wire CIN;
input [3:0] DI;
input [3:0] S;

CARRY4 c4_i(.CO(CO), .O(O), .CIN(CIN), .DI(DI), .S(S));

endmodule
