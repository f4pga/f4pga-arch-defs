`include "carry4_complete/carry4_complete.sim.v"
`include "carry4_split/carry4_split.sim.v"

(* blackbox *)
module CARRY4_TOP(CO, O, CIN, DI, S);

	output wire [3:0] CO;
	output wire [3:0] O;
	input CIN;
	input [3:0] DI;
	input [3:0] S;

endmodule
