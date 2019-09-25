`default_nettype none
`include "cblock/cblock.sim.v"

module CARRY (
	I0,
	I1,
	O0,
	O1,
	CIN,
	COUT
);
	input wire [3:0] I0;
	input wire [3:0] I1;

	output wire O0;
	output wire O1;

	// Implicit carry pins
	input wire CIN;
	output wire COUT;

	// Carry between the two blocks
	wire c;

	CBLOCK cblock0 (.I(I0), .O(O0), .CIN(CIN), .COUT(c));
	CBLOCK cblock1 (.I(I1), .O(O1), .CIN(c), .COUT(COUT));

endmodule
