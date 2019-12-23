// `include "../../primitives/ff/ff.sim.v"
`include "../../primitives/mux/mux.sim.v"
`include "logicbox.sim.v"

module TEST_CELL (D1, D2, Q);
	// input wire clk;
	input wire D1;
	input wire D2;
	output wire Q;

	wire i0;
	wire i1;
	LOGICBOX lbox0(D1, i0);
	LOGICBOX lbox1(D2, i1);

	// (* pack = "DFF" *)
	// wire d;

	parameter DS = "I0";

	MUX #(.MODE(DS)) mux0(i0, i1, Q);
	// FF ff0(clk, d, S, R, E, Q);
endmodule
