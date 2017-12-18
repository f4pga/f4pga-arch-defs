`include "mux2.v"

module MUX4(I0, I1, I2, I3, S0, S1, O);
	input wire I0;
	input wire I1;
	input wire I2;
	input wire I3;
	input wire S0;
	output wire O;

	wire m0;
	wire m1;

	MUX2 mux0    (.I0(I0), .I1(I1), .S0(.S0), .O(m0));
	MUX2 mux1    (.I0(I2), .I1(I3), .S0(.S0), .O(m1));
	MUX2 mux_out (.I0(m0), .I1(m1), .S0(.S1), .O(o));
endmodule
