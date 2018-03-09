`include "carry4/carry4.sim.v"
`include "carry4_split/carry4_split.sim.v"

(* MODES = "SPLIT, COMPLETE" *)
module CARRY4_TOP(CO, O, CIN, DI, S);

	output wire [3:0] CO;
	output wire [3:0] O;
	input CIN;
	input [3:0] DI;
	input [3:0] S;
	parameter [1023:0] MODE = "SPLIT";

	generate
		if(MODE == "SPLIT") begin
			CARRY4_SPLIT split_i(.CO(CO), .O(O), .CIN(CIN), .DI(DI), .S(S));
		end else if(MODE == "COMPLETE") begin
			CARRY4 complete_i(.CO(CO), .O(O), .CIN(CIN), .DI(DI), .S(S));
		end
	endgenerate


endmodule
