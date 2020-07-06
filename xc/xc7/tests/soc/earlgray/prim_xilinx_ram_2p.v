module prim_xilinx_ram_2p (
	clk_a_i,
	clk_b_i,
	a_req_i,
	a_write_i,
	a_addr_i,
	a_wdata_i,
	a_rdata_o,
	b_req_i,
	b_write_i,
	b_addr_i,
	b_wdata_i,
	b_rdata_o
);
	parameter signed [31:0] Width = 32;
	parameter signed [31:0] Depth = 128;
	localparam signed [31:0] Aw = $clog2(Depth);
	input clk_a_i;
	input clk_b_i;
	input a_req_i;
	input a_write_i;
	input [Aw - 1:0] a_addr_i;
	input [Width - 1:0] a_wdata_i;
	output reg [Width - 1:0] a_rdata_o;
	input b_req_i;
	input b_write_i;
	input [Aw - 1:0] b_addr_i;
	input [Width - 1:0] b_wdata_i;
	output reg [Width - 1:0] b_rdata_o;
	reg [Width - 1:0] storage [0:Depth - 1];
	always @(posedge clk_a_i)
		if (a_req_i) begin
			if (a_write_i)
				storage[a_addr_i] <= a_wdata_i;
			a_rdata_o <= storage[a_addr_i];
		end
	always @(posedge clk_b_i)
		if (b_req_i) begin
			if (b_write_i)
				storage[b_addr_i] <= b_wdata_i;
			b_rdata_o <= storage[b_addr_i];
		end
endmodule
