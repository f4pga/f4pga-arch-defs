module prim_clock_gating (
	clk_i,
	en_i,
	test_en_i,
	clk_o
);
	localparam prim_pkg_ImplXilinx = 1;
	parameter integer Impl = prim_pkg_ImplXilinx;
	input clk_i;
	input en_i;
	input test_en_i;
	output wire clk_o;
	localparam ImplGeneric = 0;
	localparam ImplXilinx = 1;
	generate
		if (Impl == ImplGeneric) begin : gen_generic
			prim_generic_clock_gating u_impl_generic(
				.clk_i(clk_i),
				.en_i(en_i),
				.test_en_i(test_en_i),
				.clk_o(clk_o)
			);
		end
		else if (Impl == ImplXilinx) begin : gen_xilinx
			prim_xilinx_clock_gating u_impl_xilinx(
				.clk_i(clk_i),
				.en_i(en_i),
				.test_en_i(test_en_i),
				.clk_o(clk_o)
			);
		end
	endgenerate
endmodule
