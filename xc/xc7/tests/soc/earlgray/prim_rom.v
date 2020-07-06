module prim_rom (
	clk_i,
	rst_ni,
	addr_i,
	cs_i,
	dout_o,
	dvalid_o
);
	localparam prim_pkg_ImplXilinx = 1;
	parameter integer Impl = prim_pkg_ImplXilinx;
	parameter signed [31:0] Width = 32;
	parameter signed [31:0] Depth = 2048;
	parameter signed [31:0] Aw = $clog2(Depth);
	input clk_i;
	input rst_ni;
	input [Aw - 1:0] addr_i;
	input cs_i;
	output wire [Width - 1:0] dout_o;
	output wire dvalid_o;
	localparam ImplGeneric = 0;
	localparam ImplXilinx = 1;
	generate
		if (Impl == ImplGeneric) begin : gen_mem_generic
			prim_generic_rom #(
				.Width(Width),
				.Depth(Depth)
			) u_impl_generic(
				.clk_i(clk_i),
				.rst_ni(rst_ni),
				.addr_i(addr_i),
				.cs_i(cs_i),
				.dout_o(dout_o),
				.dvalid_o(dvalid_o)
			);
		end
		else if (Impl == ImplXilinx) begin : gen_rom_xilinx
			prim_xilinx_rom #(
				.Width(Width),
				.Depth(Depth)
			) u_impl_generic(
				.clk_i(clk_i),
				.addr_i(addr_i),
				.cs_i(cs_i),
				.dout_o(dout_o),
				.dvalid_o(dvalid_o)
			);
		end
	endgenerate
endmodule
