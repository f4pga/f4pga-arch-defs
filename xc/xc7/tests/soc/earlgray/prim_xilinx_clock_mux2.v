module prim_xilinx_clock_mux2 (
	clk0_i,
	clk1_i,
	sel_i,
	clk_o
);
	input clk0_i;
	input clk1_i;
	input sel_i;
	output wire clk_o;
	BUFGMUX bufgmux_i(
		.S(sel_i),
		.I0(clk0_i),
		.I1(clk1_i),
		.O(clk_o)
	);
endmodule
