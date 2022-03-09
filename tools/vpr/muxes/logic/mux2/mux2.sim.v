`ifndef VPR_MUXES_LOGIC_MUX2
`define VPR_MUXES_LOGIC_MUX2

module MUX2(I0, I1, S0, O);
	input wire I0;
	input wire I1;
	input wire S0;
	output wire O;

	assign O = S0 ? I1 : I0;
endmodule

`endif
