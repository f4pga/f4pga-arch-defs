`include "../ff/ff.sim.v"
`include "../lut/lut.sim.v"
`include "../omux/omux.sim.v"

module LUTFF (C, I, O);
	parameter [0:0] OSEL = 1'b0;
	parameter [15:0] LUT_INIT = 1'b0;

	(* CLOCK *)
	input C;

	input [3:0] I;

	output O;

	wire lut_out, ff_out;

	LUT #(.INIT(LUT_INIT)) lut_i(.in(I), .out(lut_out));
	FF ff_i(.clk(C), .D(lut_out), .Q(ff_out));
	OMUX #(.S(OSEL)) omux_i(.LT(lut_out), .FF(ff_out), .O(O));

endmodule
