// D6LUT, C6LUT, B6LUT, A6LUT == W6LUT
// A fracturable 6 input LUT. Can either be;
//  - 2 * 5 input, 1 output LUT
//  - 1 * 6 input, 1 output LUT
`include "../muxes/f6mux/f6mux.sim.v"
`include "ntemplate.N5lut.sim.v"

module {N}LUT(A1, A2, A3, A4, A5, A6, O6, O5);

	input wire A1;
	input wire A2;
	input wire A3;
	input wire A4;
	input wire A5;
	input wire A6;
	output wire O5;
	output wire O6;

	wire upper_O;
	wire lower_O;

	{N}5LUT LUT5_0 (.in({{A5, A4, A3, A2, A1}}),
			.out(lower_O));

	{N}5LUT LUT5_1 (.in({{A5, A4, A3, A2, A1}}),
			.out(upper_O));

	assign O5 = lower_O;

	F6MUX F6MUX_0 (.I0(upper_O),
		       .I1(lower_O),
		       .S(A6),
		       .OUT(O6));

endmodule

