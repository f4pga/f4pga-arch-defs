`include "../../../../../../vpr/muxes/logic/mux2/mux2.sim.v"

module {N}USED(I0, O);

	input wire I0;

	parameter [0:0] S = 0;

	output wire O;

	MUX2 mux (
		.I0(I0),
		.I1(0),
		.S0(S),
		.O(O)
	);
endmodule
