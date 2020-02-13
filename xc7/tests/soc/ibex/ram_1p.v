module ram_1p (
	clk_i,
	rst_ni,
	req_i,
	we_i,
	be_i,
	addr_i,
	wdata_i,
	rvalid_o,
	rdata_o
);
	parameter signed [31:0] Depth = 128;
	input clk_i;
	input rst_ni;
	input req_i;
	input we_i;
	input [3:0] be_i;
	input [31:0] addr_i;
	input [31:0] wdata_i;
	output reg rvalid_o;
	output reg [31:0] rdata_o;
	localparam signed [31:0] Aw = $clog2(Depth);
	reg [31:0] mem [0:(Depth - 1)];
	wire [(Aw - 1):0] addr_idx;
	assign addr_idx = addr_i[((Aw - 1) + 2):2];
	wire [(31 - Aw):0] unused_addr_parts;
	assign unused_addr_parts = {addr_i[31:(Aw + 2)], addr_i[1:0]};
	always @(posedge clk_i)
		if (req_i) begin
			if (we_i) begin : sv2v_autoblock_1
				reg signed [31:0] i;
				for (i = 0; (i < 4); i = (i + 1))
					if ((be_i[i] == 1'b1))
						mem[addr_idx][(i * 8)+:8] <= wdata_i[(i * 8)+:8];
			end
			rdata_o <= mem[addr_idx];
		end
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			rvalid_o <= 1'sb0;
		else
			rvalid_o <= req_i;
	localparam MEM_FILE = "led.vmem";
	initial begin
		$display("Initializing SRAM from %s", MEM_FILE);
		$readmemh("led.vmem", mem);
	end
endmodule
