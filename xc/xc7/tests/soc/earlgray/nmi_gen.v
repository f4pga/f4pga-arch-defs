module nmi_gen (
	clk_i,
	rst_ni,
	tl_i,
	tl_o,
	intr_esc0_o,
	intr_esc1_o,
	intr_esc2_o,
	intr_esc3_o,
	esc_tx_i,
	esc_rx_o
);
	localparam top_pkg_TL_AIW = 8;
	localparam top_pkg_TL_AW = 32;
	localparam top_pkg_TL_DBW = top_pkg_TL_DW >> 3;
	localparam top_pkg_TL_DIW = 1;
	localparam top_pkg_TL_DUW = 16;
	localparam top_pkg_TL_DW = 32;
	localparam top_pkg_TL_SZW = $clog2($clog2(32 >> 3) + 1);
	localparam [31:0] N_ESC_SEV = 4;
	input clk_i;
	input rst_ni;
	input wire [((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_AW) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + top_pkg_TL_DW) + 17) - 1:0] tl_i;
	output wire [((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_DIW) + top_pkg_TL_DW) + top_pkg_TL_DUW) + 2) - 1:0] tl_o;
	output wire intr_esc0_o;
	output wire intr_esc1_o;
	output wire intr_esc2_o;
	output wire intr_esc3_o;
	input wire [(N_ESC_SEV * 2) + -1:0] esc_tx_i;
	output wire [(N_ESC_SEV * 2) + -1:0] esc_rx_o;
	wire [N_ESC_SEV - 1:0] esc_en;
	wire [15:0] reg2hw;
	wire [7:0] hw2reg;
	nmi_gen_reg_top i_reg(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.tl_i(tl_i),
		.tl_o(tl_o),
		.reg2hw(reg2hw),
		.hw2reg(hw2reg),
		.devmode_i(1'b1)
	);
	prim_intr_hw #(.Width(1)) i_intr_esc0(
		.event_intr_i(esc_en[0]),
		.reg2hw_intr_enable_q_i(reg2hw[11]),
		.reg2hw_intr_test_q_i(reg2hw[7]),
		.reg2hw_intr_test_qe_i(reg2hw[6]),
		.reg2hw_intr_state_q_i(reg2hw[15]),
		.hw2reg_intr_state_de_o(hw2reg[6]),
		.hw2reg_intr_state_d_o(hw2reg[7]),
		.intr_o(intr_esc0_o)
	);
	prim_intr_hw #(.Width(1)) i_intr_esc1(
		.event_intr_i(esc_en[1]),
		.reg2hw_intr_enable_q_i(reg2hw[10]),
		.reg2hw_intr_test_q_i(reg2hw[5]),
		.reg2hw_intr_test_qe_i(reg2hw[4]),
		.reg2hw_intr_state_q_i(reg2hw[14]),
		.hw2reg_intr_state_de_o(hw2reg[4]),
		.hw2reg_intr_state_d_o(hw2reg[5]),
		.intr_o(intr_esc1_o)
	);
	prim_intr_hw #(.Width(1)) i_intr_esc2(
		.event_intr_i(esc_en[2]),
		.reg2hw_intr_enable_q_i(reg2hw[9]),
		.reg2hw_intr_test_q_i(reg2hw[3]),
		.reg2hw_intr_test_qe_i(reg2hw[2]),
		.reg2hw_intr_state_q_i(reg2hw[13]),
		.hw2reg_intr_state_de_o(hw2reg[2]),
		.hw2reg_intr_state_d_o(hw2reg[3]),
		.intr_o(intr_esc2_o)
	);
	prim_intr_hw #(.Width(1)) i_intr_esc3(
		.event_intr_i(esc_en[3]),
		.reg2hw_intr_enable_q_i(reg2hw[8]),
		.reg2hw_intr_test_q_i(reg2hw[1]),
		.reg2hw_intr_test_qe_i(reg2hw[0]),
		.reg2hw_intr_state_q_i(reg2hw[12]),
		.hw2reg_intr_state_de_o(hw2reg[0]),
		.hw2reg_intr_state_d_o(hw2reg[1]),
		.intr_o(intr_esc3_o)
	);
	generate
		genvar k;
		for (k = 0; k < N_ESC_SEV; k = k + 1) begin : gen_esc_sev
			prim_esc_receiver i_prim_esc_receiver(
				.clk_i(clk_i),
				.rst_ni(rst_ni),
				.esc_en_o(esc_en[k]),
				.esc_rx_o(esc_rx_o[k * 2+:2]),
				.esc_tx_i(esc_tx_i[k * 2+:2])
			);
		end
	endgenerate
endmodule
