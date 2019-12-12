`include "../../primitives/ff/ff.sim.v"
`include "../../primitives/mux/mux.sim.v"

module TEST_CELL (clk, D1, D2, DS, S, R, E, Q);
	input wire clk;
	input wire D1;
	input wire D2;
	input wire DS;
	input wire S;
	input wire R;
	input wire E;
	output wire Q;

	wire d;
	MUX mux0(D1, D2, DS, d);
	FF ff0(clk, d, S, R, E, Q);
endmodule
