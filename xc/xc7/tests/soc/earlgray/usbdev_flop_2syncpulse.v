module usbdev_flop_2syncpulse (
	clk_i,
	rst_ni,
	d,
	q
);
	parameter [31:0] Width = 16;
	input wire clk_i;
	input wire rst_ni;
	input wire [Width - 1:0] d;
	output wire [Width - 1:0] q;
	wire [Width - 1:0] d_sync;
	prim_flop_2sync #(.Width(Width)) prim_flop_2sync(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.d(d),
		.q(d_sync)
	);
	reg [Width - 1:0] d_sync_q;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			d_sync_q <= 1'sb0;
		else
			d_sync_q <= d_sync;
	assign q = d_sync & ~d_sync_q;
endmodule
