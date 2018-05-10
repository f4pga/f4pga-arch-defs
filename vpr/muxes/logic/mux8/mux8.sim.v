`ifndef VPR_MUXES_LOGIC_MUX8
`define VPR_MUXES_LOGIC_MUX8

`include "../mux2/mux2.sim.v"

module MUX8(I0, I1, I2, I3, I4, I5, I6, I7, S0, S1, S2, O);
	input wire I0;
	input wire I1;
	input wire I2;
	input wire I3;
	input wire I4;
	input wire I5;
   	input wire I6;
      	input wire I7;
	input wire S0;
	input wire S1;
	input wire S2;
	output wire O;

	wire m0;
	wire m1;
	wire m2;
	wire m3;
	wire m4;
   	wire m5;

	MUX2 mux0    (.I0(I0), .I1(I1), .S0(S0), .O(m0));
	MUX2 mux1    (.I0(I2), .I1(I3), .S0(S0), .O(m1));
	MUX2 mux2    (.I0(I4), .I1(I5), .S0(S0), .O(m2));
	MUX2 mux3    (.I0(I6), .I1(I7), .S0(S0), .O(m3));
   
	MUX2 mux4    (.I0(m0), .I1(m1), .S0(S1), .O(m4));
	MUX2 mux5    (.I0(m2), .I1(m3), .S0(S1), .O(m5));

	MUX2 mux6    (.I0(m4), .I1(m5), .S0(S2), .O(O));
endmodule // MUX8

`endif //  `ifndef VPR_MUXES_LOGIC_MUX8

