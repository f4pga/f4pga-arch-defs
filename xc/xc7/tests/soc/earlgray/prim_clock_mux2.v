module prim_clock_mux2 (
	clk0_i,
	clk1_i,
	sel_i,
	clk_o
);
	localparam prim_pkg_ImplXilinx = 1;
	parameter integer Impl = prim_pkg_ImplXilinx;
	input clk0_i;
	input clk1_i;
	input sel_i;
	output wire clk_o;
	localparam ImplGeneric = 0;
	localparam ImplXilinx = 1;
	generate
		if (Impl == ImplGeneric) begin : gen_generic
			prim_generic_clock_mux2 u_impl_generic(
				.clk0_i(clk0_i),
				.clk1_i(clk1_i),
				.sel_i(sel_i),
				.clk_o(clk_o)
			);
		end
		else if (Impl == ImplXilinx) begin : gen_xilinx
			prim_xilinx_clock_mux2 u_impl_xilinx(
				.clk0_i(clk0_i),
				.clk1_i(clk1_i),
				.sel_i(sel_i),
				.clk_o(clk_o)
			);
		end
	endgenerate
endmodule
