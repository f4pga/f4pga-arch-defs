module prim_generic_ram_1p (
	clk_i,
	rst_ni,
	req_i,
	write_i,
	addr_i,
	wdata_i,
	wmask_i,
	rvalid_o,
	rdata_o
);
	parameter signed [31:0] Width = 32;
	parameter signed [31:0] Depth = 128;
	parameter signed [31:0] DataBitsPerMask = 1;
	localparam signed [31:0] Aw = $clog2(Depth);
	input clk_i;
	input rst_ni;
	input req_i;
	input write_i;
	input [Aw - 1:0] addr_i;
	input [Width - 1:0] wdata_i;
	input [Width - 1:0] wmask_i;
	output reg rvalid_o;
	output reg [Width - 1:0] rdata_o;
	localparam signed [31:0] MaskWidth = Width / DataBitsPerMask;
	reg [Width - 1:0] mem [0:Depth - 1];
	reg [MaskWidth - 1:0] wmask;
	always @(*) begin : sv2v_autoblock_147
		reg signed [31:0] i;
		for (i = 0; i < MaskWidth; i = i + 1)
			begin : create_wmask
				wmask[i] = &wmask_i[i * DataBitsPerMask+:DataBitsPerMask];
			end
	end
	always @(posedge clk_i)
		if (req_i)
			if (write_i) begin : sv2v_autoblock_148
				reg signed [31:0] i;
				for (i = 0; i < MaskWidth; i = i + 1)
					if (wmask[i])
						mem[addr_i][i * DataBitsPerMask+:DataBitsPerMask] <= wdata_i[i * DataBitsPerMask+:DataBitsPerMask];
			end
			else
				rdata_o <= mem[addr_i];
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			rvalid_o <= 1'sb0;
		else
			rvalid_o <= req_i & ~write_i;
endmodule
