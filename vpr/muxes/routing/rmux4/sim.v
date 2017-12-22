`ifndef VPR_MUXES_ROUTING_RMUX4
`define VPR_MUXES_ROUTING_RMUX4

`include "../rmux2/sim.v"

module RMUX4(I0, I1, I2, I3, O);
	parameter [0:0] S0 = 0;
	parameter [0:0] S1 = 0;

	input wire I0;
	input wire I1;
	input wire I2;
	input wire I3;
	output wire O;

	wire m0;
	wire m1;

	RMUX2 #(.S0(S0)) rmux0    (.I0(I0), .I1(I1), .O(m0));
	RMUX2 #(.S0(S0)) rmux1    (.I0(I2), .I1(I3), .O(m1));
	RMUX2 #(.S0(S1)) rmux_out (.I0(m0), .I1(m1), .O(O));
endmodule

`endif
