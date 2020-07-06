module timer_core (
	clk_i,
	rst_ni,
	active,
	prescaler,
	step,
	tick,
	mtime_d,
	mtime,
	mtimecmp,
	intr
);
	parameter signed [31:0] N = 1;
	input clk_i;
	input rst_ni;
	input active;
	input [11:0] prescaler;
	input [7:0] step;
	output wire tick;
	output wire [63:0] mtime_d;
	input [63:0] mtime;
	input [(0 >= (N - 1) ? ((2 - N) * 64) + (((N - 1) * 64) - 1) : (N * 64) + -1):(0 >= (N - 1) ? (N - 1) * 64 : 0)] mtimecmp;
	output wire [N - 1:0] intr;
	reg [11:0] tick_count;
	always @(posedge clk_i or negedge rst_ni) begin : generate_tick
		if (!rst_ni)
			tick_count <= 12'h0;
		else if (!active)
			tick_count <= 12'h0;
		else if (tick_count == prescaler)
			tick_count <= 12'h0;
		else
			tick_count <= tick_count + 1'b1;
	end
	assign tick = active & (tick_count >= prescaler);
	assign mtime_d = mtime + sv2v_cast_64(step);
	generate
		genvar t;
		for (t = 0; t < N; t = t + 1) begin : gen_intr
			assign intr[t] = active & (mtime >= mtimecmp[(0 >= (N - 1) ? t : (N - 1) - t) * 64+:64]);
		end
	endgenerate
	function automatic [63:0] sv2v_cast_64;
		input reg [63:0] inp;
		sv2v_cast_64 = inp;
	endfunction
endmodule
