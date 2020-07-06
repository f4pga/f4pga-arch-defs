module prim_generic_rom (
	clk_i,
	rst_ni,
	addr_i,
	cs_i,
	dout_o,
	dvalid_o
);
	parameter signed [31:0] Width = 32;
	parameter signed [31:0] Depth = 2048;
	parameter signed [31:0] Aw = $clog2(Depth);
	input clk_i;
	input rst_ni;
	input [Aw - 1:0] addr_i;
	input cs_i;
	output reg [Width - 1:0] dout_o;
	output reg dvalid_o;
	reg [Width - 1:0] mem [0:Depth - 1];
	always @(posedge clk_i)
		if (cs_i)
			dout_o <= mem[addr_i];
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			dvalid_o <= 1'b0;
		else
			dvalid_o <= cs_i;
	initial begin
		$display("Initializing ROM from %s", "boot_rom_fpga_nexysvideo.vmem");
		$readmemh("boot_rom_fpga_nexysvideo.vmem", mem);
	end
endmodule
