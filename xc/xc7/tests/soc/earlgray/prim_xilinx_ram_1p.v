module prim_xilinx_ram_1p (
	clk_a_i,
	a_req_i,
	a_write_i,
	a_addr_i,
	a_wdata_i,
	a_rdata_o
);
	parameter signed [31:0] Width = 32;
	parameter signed [31:0] Depth = 256;
	localparam signed [31:0] Aw = $clog2(Depth);
	input clk_a_i;
	input a_req_i;
	input a_write_i;
	input [Aw - 1:0] a_addr_i;
	input [Width - 1:0] a_wdata_i;
	output reg [Width - 1:0] a_rdata_o;
	reg [Width - 1:0] storage [0:Depth - 1];
	always @(posedge clk_a_i)
		if (a_req_i) begin
			if (a_write_i)
				storage[a_addr_i] <= a_wdata_i;
			a_rdata_o <= storage[a_addr_i];
		end
endmodule
