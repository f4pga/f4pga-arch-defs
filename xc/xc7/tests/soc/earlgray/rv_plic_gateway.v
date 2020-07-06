module rv_plic_gateway (
	clk_i,
	rst_ni,
	src,
	le,
	claim,
	complete,
	ip
);
	parameter signed [31:0] N_SOURCE = 32;
	input clk_i;
	input rst_ni;
	input [N_SOURCE - 1:0] src;
	input [N_SOURCE - 1:0] le;
	input [N_SOURCE - 1:0] claim;
	input [N_SOURCE - 1:0] complete;
	output reg [N_SOURCE - 1:0] ip;
	reg [N_SOURCE - 1:0] ia;
	reg [N_SOURCE - 1:0] set;
	reg [N_SOURCE - 1:0] src_d;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			src_d <= 1'sb0;
		else
			src_d <= src;
	always @(*) begin : sv2v_autoblock_146
		reg signed [31:0] i;
		for (i = 0; i < N_SOURCE; i = i + 1)
			set[i] = (le[i] ? src[i] & ~src_d[i] : src[i]);
	end
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			ip <= 1'sb0;
		else
			ip <= (ip | ((set & ~ia) & ~ip)) & ~(ip & claim);
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			ia <= 1'sb0;
		else
			ia <= (ia | (set & ~ia)) & ~((ia & complete) & ~ip);
endmodule
