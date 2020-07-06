module pinmux (
	clk_i,
	rst_ni,
	tl_i,
	tl_o,
	periph_to_mio_i,
	periph_to_mio_oe_i,
	mio_to_periph_o,
	mio_out_o,
	mio_oe_o,
	mio_in_i
);
	parameter signed [31:0] pinmux_reg_pkg_NMioPads = 32;
	parameter signed [31:0] pinmux_reg_pkg_NPeriphIn = 32;
	parameter signed [31:0] pinmux_reg_pkg_NPeriphOut = 32;
	localparam top_pkg_TL_AIW = 8;
	localparam top_pkg_TL_AW = 32;
	localparam top_pkg_TL_DBW = top_pkg_TL_DW >> 3;
	localparam top_pkg_TL_DIW = 1;
	localparam top_pkg_TL_DUW = 16;
	localparam top_pkg_TL_DW = 32;
	localparam top_pkg_TL_SZW = $clog2($clog2(32 >> 3) + 1);
	input clk_i;
	input rst_ni;
	input wire [((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_AW) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + top_pkg_TL_DW) + 17) - 1:0] tl_i;
	output wire [((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_DIW) + top_pkg_TL_DW) + top_pkg_TL_DUW) + 2) - 1:0] tl_o;
	input [pinmux_reg_pkg_NPeriphOut - 1:0] periph_to_mio_i;
	input [pinmux_reg_pkg_NPeriphOut - 1:0] periph_to_mio_oe_i;
	output wire [pinmux_reg_pkg_NPeriphIn - 1:0] mio_to_periph_o;
	output wire [pinmux_reg_pkg_NMioPads - 1:0] mio_out_o;
	output wire [pinmux_reg_pkg_NMioPads - 1:0] mio_oe_o;
	input [pinmux_reg_pkg_NMioPads - 1:0] mio_in_i;
	wire [383:0] reg2hw;
	pinmux_reg_top i_reg_top(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.tl_i(tl_i),
		.tl_o(tl_o),
		.reg2hw(reg2hw),
		.devmode_i(1'b1)
	);
	generate
		genvar k;
		for (k = 0; k < pinmux_reg_pkg_NPeriphIn; k = k + 1) begin : gen_periph_in
			wire [(pinmux_reg_pkg_NMioPads + 2) - 1:0] data_mux;
			assign data_mux = sv2v_cast_A78F0({mio_in_i, 1'b1, 1'b0});
			assign mio_to_periph_o[k] = data_mux[reg2hw[192 + ((k * 6) + 5)-:6]];
		end
	endgenerate
	generate
		for (k = 0; k < pinmux_reg_pkg_NMioPads; k = k + 1) begin : gen_mio_out
			wire [(pinmux_reg_pkg_NPeriphOut + 3) - 1:0] data_mux;
			wire [(pinmux_reg_pkg_NPeriphOut + 3) - 1:0] oe_mux;
			assign data_mux = sv2v_cast_A78F0({periph_to_mio_i, 1'b0, 1'b1, 1'b0});
			assign oe_mux = sv2v_cast_A78F0({periph_to_mio_oe_i, 1'b0, 1'b1, 1'b1});
			assign mio_out_o[k] = data_mux[reg2hw[(k * 6) + 5-:6]];
			assign mio_oe_o[k] = oe_mux[reg2hw[(k * 6) + 5-:6]];
		end
	endgenerate
	function automatic [(((pinmux_reg_pkg_NPeriphOut + 3) - 1) >= 0 ? pinmux_reg_pkg_NPeriphOut + 3 : 2 - (pinmux_reg_pkg_NPeriphOut + 3)) - 1:0] sv2v_cast_A78F0;
		input reg [(((pinmux_reg_pkg_NPeriphOut + 3) - 1) >= 0 ? pinmux_reg_pkg_NPeriphOut + 3 : 2 - (pinmux_reg_pkg_NPeriphOut + 3)) - 1:0] inp;
		sv2v_cast_A78F0 = inp;
	endfunction
endmodule
