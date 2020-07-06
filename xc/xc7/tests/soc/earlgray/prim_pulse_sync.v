module prim_pulse_sync (
	clk_src_i,
	rst_src_ni,
	src_pulse_i,
	clk_dst_i,
	rst_dst_ni,
	dst_pulse_o
);
	input wire clk_src_i;
	input wire rst_src_ni;
	input wire src_pulse_i;
	input wire clk_dst_i;
	input wire rst_dst_ni;
	output wire dst_pulse_o;
	reg src_level;
	always @(posedge clk_src_i or negedge rst_src_ni)
		if (!rst_src_ni)
			src_level <= 1'b0;
		else
			src_level <= src_level ^ src_pulse_i;
	wire dst_level;
	prim_flop_2sync #(.Width(1)) prim_flop_2sync(
		.d(src_level),
		.clk_i(clk_dst_i),
		.rst_ni(rst_dst_ni),
		.q(dst_level)
	);
	reg dst_level_q;
	always @(posedge clk_dst_i or negedge rst_dst_ni)
		if (!rst_dst_ni)
			dst_level_q <= 1'b0;
		else
			dst_level_q <= dst_level;
	assign dst_pulse_o = dst_level_q ^ dst_level;
endmodule
