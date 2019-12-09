`include "../../primitives/ff/ff.sim.v"

module TEST_CELL (clk, D, S, R, E, Q);
	input wire clk;
	input wire D;
	input wire S;
	input wire R;
	input wire E;
	output wire Q;

	FF ff0(clk, D, S, R, E, Q);
endmodule
