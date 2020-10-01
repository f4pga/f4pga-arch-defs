`include "../../../../../../vpr/muxes/logic/mux2/mux2.sim.v"

module CLKINV(CLK, OUT);
	input wire CLK;

	parameter INV = 0;
	output wire OUT;

	MUX2 mux (
		.I0(CLK),
		.I1(~CLK),
		.S0(INV),
		.O(OUT)
	);
endmodule
