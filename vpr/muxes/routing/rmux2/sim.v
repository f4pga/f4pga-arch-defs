`ifndef VPR_MUXES_ROUTING_RMUX2
`define VPR_MUXES_ROUTING_RMUX2

module RMUX2(I0, I1, O);
	parameter [0:0] S0 = 0;

	input wire I0;
	input wire I1;
	output wire O;

	assign O = S0 ? I0 : I1;
endmodule

`endif
