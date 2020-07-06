module pinmux_reg_top (
	clk_i,
	rst_ni,
	tl_i,
	tl_o,
	reg2hw,
	devmode_i
);
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
	output wire [383:0] reg2hw;
	input devmode_i;
	parameter signed [31:0] NPeriphIn = 32;
	parameter signed [31:0] NPeriphOut = 32;
	parameter signed [31:0] NMioPads = 32;
	parameter [5:0] PINMUX_REGEN_OFFSET = 6'h 0;
	parameter [5:0] PINMUX_PERIPH_INSEL0_OFFSET = 6'h 4;
	parameter [5:0] PINMUX_PERIPH_INSEL1_OFFSET = 6'h 8;
	parameter [5:0] PINMUX_PERIPH_INSEL2_OFFSET = 6'h c;
	parameter [5:0] PINMUX_PERIPH_INSEL3_OFFSET = 6'h 10;
	parameter [5:0] PINMUX_PERIPH_INSEL4_OFFSET = 6'h 14;
	parameter [5:0] PINMUX_PERIPH_INSEL5_OFFSET = 6'h 18;
	parameter [5:0] PINMUX_PERIPH_INSEL6_OFFSET = 6'h 1c;
	parameter [5:0] PINMUX_MIO_OUTSEL0_OFFSET = 6'h 20;
	parameter [5:0] PINMUX_MIO_OUTSEL1_OFFSET = 6'h 24;
	parameter [5:0] PINMUX_MIO_OUTSEL2_OFFSET = 6'h 28;
	parameter [5:0] PINMUX_MIO_OUTSEL3_OFFSET = 6'h 2c;
	parameter [5:0] PINMUX_MIO_OUTSEL4_OFFSET = 6'h 30;
	parameter [5:0] PINMUX_MIO_OUTSEL5_OFFSET = 6'h 34;
	parameter [5:0] PINMUX_MIO_OUTSEL6_OFFSET = 6'h 38;
	parameter [59:0] PINMUX_PERMIT = {4'b 0001, 4'b 1111, 4'b 1111, 4'b 1111, 4'b 1111, 4'b 1111, 4'b 1111, 4'b 0011, 4'b 1111, 4'b 1111, 4'b 1111, 4'b 1111, 4'b 1111, 4'b 1111, 4'b 0011};
	localparam PINMUX_REGEN = 0;
	localparam PINMUX_PERIPH_INSEL0 = 1;
	localparam PINMUX_MIO_OUTSEL2 = 10;
	localparam PINMUX_MIO_OUTSEL3 = 11;
	localparam PINMUX_MIO_OUTSEL4 = 12;
	localparam PINMUX_MIO_OUTSEL5 = 13;
	localparam PINMUX_MIO_OUTSEL6 = 14;
	localparam PINMUX_PERIPH_INSEL1 = 2;
	localparam PINMUX_PERIPH_INSEL2 = 3;
	localparam PINMUX_PERIPH_INSEL3 = 4;
	localparam PINMUX_PERIPH_INSEL4 = 5;
	localparam PINMUX_PERIPH_INSEL5 = 6;
	localparam PINMUX_PERIPH_INSEL6 = 7;
	localparam PINMUX_MIO_OUTSEL0 = 8;
	localparam PINMUX_MIO_OUTSEL1 = 9;
	localparam signed [31:0] AW = 6;
	localparam signed [31:0] DW = 32;
	localparam signed [31:0] DBW = DW / 8;
	wire reg_we;
	wire reg_re;
	wire [AW - 1:0] reg_addr;
	wire [DW - 1:0] reg_wdata;
	wire [DBW - 1:0] reg_be;
	wire [DW - 1:0] reg_rdata;
	wire reg_error;
	wire addrmiss;
	reg wr_err;
	reg [DW - 1:0] reg_rdata_next;
	wire [((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_AW) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + top_pkg_TL_DW) + 17) - 1:0] tl_reg_h2d;
	wire [((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_DIW) + top_pkg_TL_DW) + top_pkg_TL_DUW) + 2) - 1:0] tl_reg_d2h;
	assign tl_reg_h2d = tl_i;
	assign tl_o = tl_reg_d2h;
	tlul_adapter_reg #(
		.RegAw(AW),
		.RegDw(DW)
	) u_reg_if(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.tl_i(tl_reg_h2d),
		.tl_o(tl_reg_d2h),
		.we_o(reg_we),
		.re_o(reg_re),
		.addr_o(reg_addr),
		.wdata_o(reg_wdata),
		.be_o(reg_be),
		.rdata_i(reg_rdata),
		.error_i(reg_error)
	);
	assign reg_rdata = reg_rdata_next;
	assign reg_error = (devmode_i & addrmiss) | wr_err;
	wire regen_qs;
	wire regen_wd;
	wire regen_we;
	wire [5:0] periph_insel0_in0_qs;
	wire [5:0] periph_insel0_in0_wd;
	wire periph_insel0_in0_we;
	wire [5:0] periph_insel0_in1_qs;
	wire [5:0] periph_insel0_in1_wd;
	wire periph_insel0_in1_we;
	wire [5:0] periph_insel0_in2_qs;
	wire [5:0] periph_insel0_in2_wd;
	wire periph_insel0_in2_we;
	wire [5:0] periph_insel0_in3_qs;
	wire [5:0] periph_insel0_in3_wd;
	wire periph_insel0_in3_we;
	wire [5:0] periph_insel0_in4_qs;
	wire [5:0] periph_insel0_in4_wd;
	wire periph_insel0_in4_we;
	wire [5:0] periph_insel1_in5_qs;
	wire [5:0] periph_insel1_in5_wd;
	wire periph_insel1_in5_we;
	wire [5:0] periph_insel1_in6_qs;
	wire [5:0] periph_insel1_in6_wd;
	wire periph_insel1_in6_we;
	wire [5:0] periph_insel1_in7_qs;
	wire [5:0] periph_insel1_in7_wd;
	wire periph_insel1_in7_we;
	wire [5:0] periph_insel1_in8_qs;
	wire [5:0] periph_insel1_in8_wd;
	wire periph_insel1_in8_we;
	wire [5:0] periph_insel1_in9_qs;
	wire [5:0] periph_insel1_in9_wd;
	wire periph_insel1_in9_we;
	wire [5:0] periph_insel2_in10_qs;
	wire [5:0] periph_insel2_in10_wd;
	wire periph_insel2_in10_we;
	wire [5:0] periph_insel2_in11_qs;
	wire [5:0] periph_insel2_in11_wd;
	wire periph_insel2_in11_we;
	wire [5:0] periph_insel2_in12_qs;
	wire [5:0] periph_insel2_in12_wd;
	wire periph_insel2_in12_we;
	wire [5:0] periph_insel2_in13_qs;
	wire [5:0] periph_insel2_in13_wd;
	wire periph_insel2_in13_we;
	wire [5:0] periph_insel2_in14_qs;
	wire [5:0] periph_insel2_in14_wd;
	wire periph_insel2_in14_we;
	wire [5:0] periph_insel3_in15_qs;
	wire [5:0] periph_insel3_in15_wd;
	wire periph_insel3_in15_we;
	wire [5:0] periph_insel3_in16_qs;
	wire [5:0] periph_insel3_in16_wd;
	wire periph_insel3_in16_we;
	wire [5:0] periph_insel3_in17_qs;
	wire [5:0] periph_insel3_in17_wd;
	wire periph_insel3_in17_we;
	wire [5:0] periph_insel3_in18_qs;
	wire [5:0] periph_insel3_in18_wd;
	wire periph_insel3_in18_we;
	wire [5:0] periph_insel3_in19_qs;
	wire [5:0] periph_insel3_in19_wd;
	wire periph_insel3_in19_we;
	wire [5:0] periph_insel4_in20_qs;
	wire [5:0] periph_insel4_in20_wd;
	wire periph_insel4_in20_we;
	wire [5:0] periph_insel4_in21_qs;
	wire [5:0] periph_insel4_in21_wd;
	wire periph_insel4_in21_we;
	wire [5:0] periph_insel4_in22_qs;
	wire [5:0] periph_insel4_in22_wd;
	wire periph_insel4_in22_we;
	wire [5:0] periph_insel4_in23_qs;
	wire [5:0] periph_insel4_in23_wd;
	wire periph_insel4_in23_we;
	wire [5:0] periph_insel4_in24_qs;
	wire [5:0] periph_insel4_in24_wd;
	wire periph_insel4_in24_we;
	wire [5:0] periph_insel5_in25_qs;
	wire [5:0] periph_insel5_in25_wd;
	wire periph_insel5_in25_we;
	wire [5:0] periph_insel5_in26_qs;
	wire [5:0] periph_insel5_in26_wd;
	wire periph_insel5_in26_we;
	wire [5:0] periph_insel5_in27_qs;
	wire [5:0] periph_insel5_in27_wd;
	wire periph_insel5_in27_we;
	wire [5:0] periph_insel5_in28_qs;
	wire [5:0] periph_insel5_in28_wd;
	wire periph_insel5_in28_we;
	wire [5:0] periph_insel5_in29_qs;
	wire [5:0] periph_insel5_in29_wd;
	wire periph_insel5_in29_we;
	wire [5:0] periph_insel6_in30_qs;
	wire [5:0] periph_insel6_in30_wd;
	wire periph_insel6_in30_we;
	wire [5:0] periph_insel6_in31_qs;
	wire [5:0] periph_insel6_in31_wd;
	wire periph_insel6_in31_we;
	wire [5:0] mio_outsel0_out0_qs;
	wire [5:0] mio_outsel0_out0_wd;
	wire mio_outsel0_out0_we;
	wire [5:0] mio_outsel0_out1_qs;
	wire [5:0] mio_outsel0_out1_wd;
	wire mio_outsel0_out1_we;
	wire [5:0] mio_outsel0_out2_qs;
	wire [5:0] mio_outsel0_out2_wd;
	wire mio_outsel0_out2_we;
	wire [5:0] mio_outsel0_out3_qs;
	wire [5:0] mio_outsel0_out3_wd;
	wire mio_outsel0_out3_we;
	wire [5:0] mio_outsel0_out4_qs;
	wire [5:0] mio_outsel0_out4_wd;
	wire mio_outsel0_out4_we;
	wire [5:0] mio_outsel1_out5_qs;
	wire [5:0] mio_outsel1_out5_wd;
	wire mio_outsel1_out5_we;
	wire [5:0] mio_outsel1_out6_qs;
	wire [5:0] mio_outsel1_out6_wd;
	wire mio_outsel1_out6_we;
	wire [5:0] mio_outsel1_out7_qs;
	wire [5:0] mio_outsel1_out7_wd;
	wire mio_outsel1_out7_we;
	wire [5:0] mio_outsel1_out8_qs;
	wire [5:0] mio_outsel1_out8_wd;
	wire mio_outsel1_out8_we;
	wire [5:0] mio_outsel1_out9_qs;
	wire [5:0] mio_outsel1_out9_wd;
	wire mio_outsel1_out9_we;
	wire [5:0] mio_outsel2_out10_qs;
	wire [5:0] mio_outsel2_out10_wd;
	wire mio_outsel2_out10_we;
	wire [5:0] mio_outsel2_out11_qs;
	wire [5:0] mio_outsel2_out11_wd;
	wire mio_outsel2_out11_we;
	wire [5:0] mio_outsel2_out12_qs;
	wire [5:0] mio_outsel2_out12_wd;
	wire mio_outsel2_out12_we;
	wire [5:0] mio_outsel2_out13_qs;
	wire [5:0] mio_outsel2_out13_wd;
	wire mio_outsel2_out13_we;
	wire [5:0] mio_outsel2_out14_qs;
	wire [5:0] mio_outsel2_out14_wd;
	wire mio_outsel2_out14_we;
	wire [5:0] mio_outsel3_out15_qs;
	wire [5:0] mio_outsel3_out15_wd;
	wire mio_outsel3_out15_we;
	wire [5:0] mio_outsel3_out16_qs;
	wire [5:0] mio_outsel3_out16_wd;
	wire mio_outsel3_out16_we;
	wire [5:0] mio_outsel3_out17_qs;
	wire [5:0] mio_outsel3_out17_wd;
	wire mio_outsel3_out17_we;
	wire [5:0] mio_outsel3_out18_qs;
	wire [5:0] mio_outsel3_out18_wd;
	wire mio_outsel3_out18_we;
	wire [5:0] mio_outsel3_out19_qs;
	wire [5:0] mio_outsel3_out19_wd;
	wire mio_outsel3_out19_we;
	wire [5:0] mio_outsel4_out20_qs;
	wire [5:0] mio_outsel4_out20_wd;
	wire mio_outsel4_out20_we;
	wire [5:0] mio_outsel4_out21_qs;
	wire [5:0] mio_outsel4_out21_wd;
	wire mio_outsel4_out21_we;
	wire [5:0] mio_outsel4_out22_qs;
	wire [5:0] mio_outsel4_out22_wd;
	wire mio_outsel4_out22_we;
	wire [5:0] mio_outsel4_out23_qs;
	wire [5:0] mio_outsel4_out23_wd;
	wire mio_outsel4_out23_we;
	wire [5:0] mio_outsel4_out24_qs;
	wire [5:0] mio_outsel4_out24_wd;
	wire mio_outsel4_out24_we;
	wire [5:0] mio_outsel5_out25_qs;
	wire [5:0] mio_outsel5_out25_wd;
	wire mio_outsel5_out25_we;
	wire [5:0] mio_outsel5_out26_qs;
	wire [5:0] mio_outsel5_out26_wd;
	wire mio_outsel5_out26_we;
	wire [5:0] mio_outsel5_out27_qs;
	wire [5:0] mio_outsel5_out27_wd;
	wire mio_outsel5_out27_we;
	wire [5:0] mio_outsel5_out28_qs;
	wire [5:0] mio_outsel5_out28_wd;
	wire mio_outsel5_out28_we;
	wire [5:0] mio_outsel5_out29_qs;
	wire [5:0] mio_outsel5_out29_wd;
	wire mio_outsel5_out29_we;
	wire [5:0] mio_outsel6_out30_qs;
	wire [5:0] mio_outsel6_out30_wd;
	wire mio_outsel6_out30_we;
	wire [5:0] mio_outsel6_out31_qs;
	wire [5:0] mio_outsel6_out31_wd;
	wire mio_outsel6_out31_we;
	prim_subreg #(
		.DW(1),
		.SWACCESS("W0C"),
		.RESVAL(1'h1)
	) u_regen(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(regen_we),
		.wd(regen_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(),
		.qs(regen_qs)
	);
	prim_subreg #(
		.DW(6),
		.SWACCESS("RW"),
		.RESVAL(6'h0)
	) u_periph_insel0_in0(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(periph_insel0_in0_we & regen_qs),
		.wd(periph_insel0_in0_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[197-:6]),
		.qs(periph_insel0_in0_qs)
	);
	prim_subreg #(
		.DW(6),
		.SWACCESS("RW"),
		.RESVAL(6'h0)
	) u_periph_insel0_in1(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(periph_insel0_in1_we & regen_qs),
		.wd(periph_insel0_in1_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[203-:6]),
		.qs(periph_insel0_in1_qs)
	);
	prim_subreg #(
		.DW(6),
		.SWACCESS("RW"),
		.RESVAL(6'h0)
	) u_periph_insel0_in2(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(periph_insel0_in2_we & regen_qs),
		.wd(periph_insel0_in2_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[209-:6]),
		.qs(periph_insel0_in2_qs)
	);
	prim_subreg #(
		.DW(6),
		.SWACCESS("RW"),
		.RESVAL(6'h0)
	) u_periph_insel0_in3(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(periph_insel0_in3_we & regen_qs),
		.wd(periph_insel0_in3_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[215-:6]),
		.qs(periph_insel0_in3_qs)
	);
	prim_subreg #(
		.DW(6),
		.SWACCESS("RW"),
		.RESVAL(6'h0)
	) u_periph_insel0_in4(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(periph_insel0_in4_we & regen_qs),
		.wd(periph_insel0_in4_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[221-:6]),
		.qs(periph_insel0_in4_qs)
	);
	prim_subreg #(
		.DW(6),
		.SWACCESS("RW"),
		.RESVAL(6'h0)
	) u_periph_insel1_in5(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(periph_insel1_in5_we & regen_qs),
		.wd(periph_insel1_in5_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[227-:6]),
		.qs(periph_insel1_in5_qs)
	);
	prim_subreg #(
		.DW(6),
		.SWACCESS("RW"),
		.RESVAL(6'h0)
	) u_periph_insel1_in6(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(periph_insel1_in6_we & regen_qs),
		.wd(periph_insel1_in6_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[233-:6]),
		.qs(periph_insel1_in6_qs)
	);
	prim_subreg #(
		.DW(6),
		.SWACCESS("RW"),
		.RESVAL(6'h0)
	) u_periph_insel1_in7(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(periph_insel1_in7_we & regen_qs),
		.wd(periph_insel1_in7_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[239-:6]),
		.qs(periph_insel1_in7_qs)
	);
	prim_subreg #(
		.DW(6),
		.SWACCESS("RW"),
		.RESVAL(6'h0)
	) u_periph_insel1_in8(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(periph_insel1_in8_we & regen_qs),
		.wd(periph_insel1_in8_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[245-:6]),
		.qs(periph_insel1_in8_qs)
	);
	prim_subreg #(
		.DW(6),
		.SWACCESS("RW"),
		.RESVAL(6'h0)
	) u_periph_insel1_in9(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(periph_insel1_in9_we & regen_qs),
		.wd(periph_insel1_in9_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[251-:6]),
		.qs(periph_insel1_in9_qs)
	);
	prim_subreg #(
		.DW(6),
		.SWACCESS("RW"),
		.RESVAL(6'h0)
	) u_periph_insel2_in10(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(periph_insel2_in10_we & regen_qs),
		.wd(periph_insel2_in10_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[257-:6]),
		.qs(periph_insel2_in10_qs)
	);
	prim_subreg #(
		.DW(6),
		.SWACCESS("RW"),
		.RESVAL(6'h0)
	) u_periph_insel2_in11(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(periph_insel2_in11_we & regen_qs),
		.wd(periph_insel2_in11_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[263-:6]),
		.qs(periph_insel2_in11_qs)
	);
	prim_subreg #(
		.DW(6),
		.SWACCESS("RW"),
		.RESVAL(6'h0)
	) u_periph_insel2_in12(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(periph_insel2_in12_we & regen_qs),
		.wd(periph_insel2_in12_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[269-:6]),
		.qs(periph_insel2_in12_qs)
	);
	prim_subreg #(
		.DW(6),
		.SWACCESS("RW"),
		.RESVAL(6'h0)
	) u_periph_insel2_in13(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(periph_insel2_in13_we & regen_qs),
		.wd(periph_insel2_in13_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[275-:6]),
		.qs(periph_insel2_in13_qs)
	);
	prim_subreg #(
		.DW(6),
		.SWACCESS("RW"),
		.RESVAL(6'h0)
	) u_periph_insel2_in14(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(periph_insel2_in14_we & regen_qs),
		.wd(periph_insel2_in14_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[281-:6]),
		.qs(periph_insel2_in14_qs)
	);
	prim_subreg #(
		.DW(6),
		.SWACCESS("RW"),
		.RESVAL(6'h0)
	) u_periph_insel3_in15(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(periph_insel3_in15_we & regen_qs),
		.wd(periph_insel3_in15_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[287-:6]),
		.qs(periph_insel3_in15_qs)
	);
	prim_subreg #(
		.DW(6),
		.SWACCESS("RW"),
		.RESVAL(6'h0)
	) u_periph_insel3_in16(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(periph_insel3_in16_we & regen_qs),
		.wd(periph_insel3_in16_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[293-:6]),
		.qs(periph_insel3_in16_qs)
	);
	prim_subreg #(
		.DW(6),
		.SWACCESS("RW"),
		.RESVAL(6'h0)
	) u_periph_insel3_in17(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(periph_insel3_in17_we & regen_qs),
		.wd(periph_insel3_in17_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[299-:6]),
		.qs(periph_insel3_in17_qs)
	);
	prim_subreg #(
		.DW(6),
		.SWACCESS("RW"),
		.RESVAL(6'h0)
	) u_periph_insel3_in18(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(periph_insel3_in18_we & regen_qs),
		.wd(periph_insel3_in18_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[305-:6]),
		.qs(periph_insel3_in18_qs)
	);
	prim_subreg #(
		.DW(6),
		.SWACCESS("RW"),
		.RESVAL(6'h0)
	) u_periph_insel3_in19(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(periph_insel3_in19_we & regen_qs),
		.wd(periph_insel3_in19_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[311-:6]),
		.qs(periph_insel3_in19_qs)
	);
	prim_subreg #(
		.DW(6),
		.SWACCESS("RW"),
		.RESVAL(6'h0)
	) u_periph_insel4_in20(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(periph_insel4_in20_we & regen_qs),
		.wd(periph_insel4_in20_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[317-:6]),
		.qs(periph_insel4_in20_qs)
	);
	prim_subreg #(
		.DW(6),
		.SWACCESS("RW"),
		.RESVAL(6'h0)
	) u_periph_insel4_in21(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(periph_insel4_in21_we & regen_qs),
		.wd(periph_insel4_in21_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[323-:6]),
		.qs(periph_insel4_in21_qs)
	);
	prim_subreg #(
		.DW(6),
		.SWACCESS("RW"),
		.RESVAL(6'h0)
	) u_periph_insel4_in22(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(periph_insel4_in22_we & regen_qs),
		.wd(periph_insel4_in22_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[329-:6]),
		.qs(periph_insel4_in22_qs)
	);
	prim_subreg #(
		.DW(6),
		.SWACCESS("RW"),
		.RESVAL(6'h0)
	) u_periph_insel4_in23(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(periph_insel4_in23_we & regen_qs),
		.wd(periph_insel4_in23_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[335-:6]),
		.qs(periph_insel4_in23_qs)
	);
	prim_subreg #(
		.DW(6),
		.SWACCESS("RW"),
		.RESVAL(6'h0)
	) u_periph_insel4_in24(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(periph_insel4_in24_we & regen_qs),
		.wd(periph_insel4_in24_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[341-:6]),
		.qs(periph_insel4_in24_qs)
	);
	prim_subreg #(
		.DW(6),
		.SWACCESS("RW"),
		.RESVAL(6'h0)
	) u_periph_insel5_in25(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(periph_insel5_in25_we & regen_qs),
		.wd(periph_insel5_in25_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[347-:6]),
		.qs(periph_insel5_in25_qs)
	);
	prim_subreg #(
		.DW(6),
		.SWACCESS("RW"),
		.RESVAL(6'h0)
	) u_periph_insel5_in26(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(periph_insel5_in26_we & regen_qs),
		.wd(periph_insel5_in26_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[353-:6]),
		.qs(periph_insel5_in26_qs)
	);
	prim_subreg #(
		.DW(6),
		.SWACCESS("RW"),
		.RESVAL(6'h0)
	) u_periph_insel5_in27(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(periph_insel5_in27_we & regen_qs),
		.wd(periph_insel5_in27_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[359-:6]),
		.qs(periph_insel5_in27_qs)
	);
	prim_subreg #(
		.DW(6),
		.SWACCESS("RW"),
		.RESVAL(6'h0)
	) u_periph_insel5_in28(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(periph_insel5_in28_we & regen_qs),
		.wd(periph_insel5_in28_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[365-:6]),
		.qs(periph_insel5_in28_qs)
	);
	prim_subreg #(
		.DW(6),
		.SWACCESS("RW"),
		.RESVAL(6'h0)
	) u_periph_insel5_in29(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(periph_insel5_in29_we & regen_qs),
		.wd(periph_insel5_in29_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[371-:6]),
		.qs(periph_insel5_in29_qs)
	);
	prim_subreg #(
		.DW(6),
		.SWACCESS("RW"),
		.RESVAL(6'h0)
	) u_periph_insel6_in30(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(periph_insel6_in30_we & regen_qs),
		.wd(periph_insel6_in30_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[377-:6]),
		.qs(periph_insel6_in30_qs)
	);
	prim_subreg #(
		.DW(6),
		.SWACCESS("RW"),
		.RESVAL(6'h0)
	) u_periph_insel6_in31(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(periph_insel6_in31_we & regen_qs),
		.wd(periph_insel6_in31_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[383-:6]),
		.qs(periph_insel6_in31_qs)
	);
	prim_subreg #(
		.DW(6),
		.SWACCESS("RW"),
		.RESVAL(6'h2)
	) u_mio_outsel0_out0(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(mio_outsel0_out0_we & regen_qs),
		.wd(mio_outsel0_out0_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[5-:6]),
		.qs(mio_outsel0_out0_qs)
	);
	prim_subreg #(
		.DW(6),
		.SWACCESS("RW"),
		.RESVAL(6'h2)
	) u_mio_outsel0_out1(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(mio_outsel0_out1_we & regen_qs),
		.wd(mio_outsel0_out1_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[11-:6]),
		.qs(mio_outsel0_out1_qs)
	);
	prim_subreg #(
		.DW(6),
		.SWACCESS("RW"),
		.RESVAL(6'h2)
	) u_mio_outsel0_out2(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(mio_outsel0_out2_we & regen_qs),
		.wd(mio_outsel0_out2_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[17-:6]),
		.qs(mio_outsel0_out2_qs)
	);
	prim_subreg #(
		.DW(6),
		.SWACCESS("RW"),
		.RESVAL(6'h2)
	) u_mio_outsel0_out3(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(mio_outsel0_out3_we & regen_qs),
		.wd(mio_outsel0_out3_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[23-:6]),
		.qs(mio_outsel0_out3_qs)
	);
	prim_subreg #(
		.DW(6),
		.SWACCESS("RW"),
		.RESVAL(6'h2)
	) u_mio_outsel0_out4(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(mio_outsel0_out4_we & regen_qs),
		.wd(mio_outsel0_out4_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[29-:6]),
		.qs(mio_outsel0_out4_qs)
	);
	prim_subreg #(
		.DW(6),
		.SWACCESS("RW"),
		.RESVAL(6'h2)
	) u_mio_outsel1_out5(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(mio_outsel1_out5_we & regen_qs),
		.wd(mio_outsel1_out5_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[35-:6]),
		.qs(mio_outsel1_out5_qs)
	);
	prim_subreg #(
		.DW(6),
		.SWACCESS("RW"),
		.RESVAL(6'h2)
	) u_mio_outsel1_out6(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(mio_outsel1_out6_we & regen_qs),
		.wd(mio_outsel1_out6_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[41-:6]),
		.qs(mio_outsel1_out6_qs)
	);
	prim_subreg #(
		.DW(6),
		.SWACCESS("RW"),
		.RESVAL(6'h2)
	) u_mio_outsel1_out7(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(mio_outsel1_out7_we & regen_qs),
		.wd(mio_outsel1_out7_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[47-:6]),
		.qs(mio_outsel1_out7_qs)
	);
	prim_subreg #(
		.DW(6),
		.SWACCESS("RW"),
		.RESVAL(6'h2)
	) u_mio_outsel1_out8(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(mio_outsel1_out8_we & regen_qs),
		.wd(mio_outsel1_out8_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[53-:6]),
		.qs(mio_outsel1_out8_qs)
	);
	prim_subreg #(
		.DW(6),
		.SWACCESS("RW"),
		.RESVAL(6'h2)
	) u_mio_outsel1_out9(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(mio_outsel1_out9_we & regen_qs),
		.wd(mio_outsel1_out9_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[59-:6]),
		.qs(mio_outsel1_out9_qs)
	);
	prim_subreg #(
		.DW(6),
		.SWACCESS("RW"),
		.RESVAL(6'h2)
	) u_mio_outsel2_out10(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(mio_outsel2_out10_we & regen_qs),
		.wd(mio_outsel2_out10_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[65-:6]),
		.qs(mio_outsel2_out10_qs)
	);
	prim_subreg #(
		.DW(6),
		.SWACCESS("RW"),
		.RESVAL(6'h2)
	) u_mio_outsel2_out11(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(mio_outsel2_out11_we & regen_qs),
		.wd(mio_outsel2_out11_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[71-:6]),
		.qs(mio_outsel2_out11_qs)
	);
	prim_subreg #(
		.DW(6),
		.SWACCESS("RW"),
		.RESVAL(6'h2)
	) u_mio_outsel2_out12(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(mio_outsel2_out12_we & regen_qs),
		.wd(mio_outsel2_out12_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[77-:6]),
		.qs(mio_outsel2_out12_qs)
	);
	prim_subreg #(
		.DW(6),
		.SWACCESS("RW"),
		.RESVAL(6'h2)
	) u_mio_outsel2_out13(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(mio_outsel2_out13_we & regen_qs),
		.wd(mio_outsel2_out13_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[83-:6]),
		.qs(mio_outsel2_out13_qs)
	);
	prim_subreg #(
		.DW(6),
		.SWACCESS("RW"),
		.RESVAL(6'h2)
	) u_mio_outsel2_out14(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(mio_outsel2_out14_we & regen_qs),
		.wd(mio_outsel2_out14_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[89-:6]),
		.qs(mio_outsel2_out14_qs)
	);
	prim_subreg #(
		.DW(6),
		.SWACCESS("RW"),
		.RESVAL(6'h2)
	) u_mio_outsel3_out15(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(mio_outsel3_out15_we & regen_qs),
		.wd(mio_outsel3_out15_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[95-:6]),
		.qs(mio_outsel3_out15_qs)
	);
	prim_subreg #(
		.DW(6),
		.SWACCESS("RW"),
		.RESVAL(6'h2)
	) u_mio_outsel3_out16(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(mio_outsel3_out16_we & regen_qs),
		.wd(mio_outsel3_out16_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[101-:6]),
		.qs(mio_outsel3_out16_qs)
	);
	prim_subreg #(
		.DW(6),
		.SWACCESS("RW"),
		.RESVAL(6'h2)
	) u_mio_outsel3_out17(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(mio_outsel3_out17_we & regen_qs),
		.wd(mio_outsel3_out17_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[107-:6]),
		.qs(mio_outsel3_out17_qs)
	);
	prim_subreg #(
		.DW(6),
		.SWACCESS("RW"),
		.RESVAL(6'h2)
	) u_mio_outsel3_out18(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(mio_outsel3_out18_we & regen_qs),
		.wd(mio_outsel3_out18_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[113-:6]),
		.qs(mio_outsel3_out18_qs)
	);
	prim_subreg #(
		.DW(6),
		.SWACCESS("RW"),
		.RESVAL(6'h2)
	) u_mio_outsel3_out19(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(mio_outsel3_out19_we & regen_qs),
		.wd(mio_outsel3_out19_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[119-:6]),
		.qs(mio_outsel3_out19_qs)
	);
	prim_subreg #(
		.DW(6),
		.SWACCESS("RW"),
		.RESVAL(6'h2)
	) u_mio_outsel4_out20(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(mio_outsel4_out20_we & regen_qs),
		.wd(mio_outsel4_out20_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[125-:6]),
		.qs(mio_outsel4_out20_qs)
	);
	prim_subreg #(
		.DW(6),
		.SWACCESS("RW"),
		.RESVAL(6'h2)
	) u_mio_outsel4_out21(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(mio_outsel4_out21_we & regen_qs),
		.wd(mio_outsel4_out21_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[131-:6]),
		.qs(mio_outsel4_out21_qs)
	);
	prim_subreg #(
		.DW(6),
		.SWACCESS("RW"),
		.RESVAL(6'h2)
	) u_mio_outsel4_out22(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(mio_outsel4_out22_we & regen_qs),
		.wd(mio_outsel4_out22_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[137-:6]),
		.qs(mio_outsel4_out22_qs)
	);
	prim_subreg #(
		.DW(6),
		.SWACCESS("RW"),
		.RESVAL(6'h2)
	) u_mio_outsel4_out23(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(mio_outsel4_out23_we & regen_qs),
		.wd(mio_outsel4_out23_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[143-:6]),
		.qs(mio_outsel4_out23_qs)
	);
	prim_subreg #(
		.DW(6),
		.SWACCESS("RW"),
		.RESVAL(6'h2)
	) u_mio_outsel4_out24(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(mio_outsel4_out24_we & regen_qs),
		.wd(mio_outsel4_out24_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[149-:6]),
		.qs(mio_outsel4_out24_qs)
	);
	prim_subreg #(
		.DW(6),
		.SWACCESS("RW"),
		.RESVAL(6'h2)
	) u_mio_outsel5_out25(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(mio_outsel5_out25_we & regen_qs),
		.wd(mio_outsel5_out25_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[155-:6]),
		.qs(mio_outsel5_out25_qs)
	);
	prim_subreg #(
		.DW(6),
		.SWACCESS("RW"),
		.RESVAL(6'h2)
	) u_mio_outsel5_out26(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(mio_outsel5_out26_we & regen_qs),
		.wd(mio_outsel5_out26_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[161-:6]),
		.qs(mio_outsel5_out26_qs)
	);
	prim_subreg #(
		.DW(6),
		.SWACCESS("RW"),
		.RESVAL(6'h2)
	) u_mio_outsel5_out27(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(mio_outsel5_out27_we & regen_qs),
		.wd(mio_outsel5_out27_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[167-:6]),
		.qs(mio_outsel5_out27_qs)
	);
	prim_subreg #(
		.DW(6),
		.SWACCESS("RW"),
		.RESVAL(6'h2)
	) u_mio_outsel5_out28(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(mio_outsel5_out28_we & regen_qs),
		.wd(mio_outsel5_out28_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[173-:6]),
		.qs(mio_outsel5_out28_qs)
	);
	prim_subreg #(
		.DW(6),
		.SWACCESS("RW"),
		.RESVAL(6'h2)
	) u_mio_outsel5_out29(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(mio_outsel5_out29_we & regen_qs),
		.wd(mio_outsel5_out29_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[179-:6]),
		.qs(mio_outsel5_out29_qs)
	);
	prim_subreg #(
		.DW(6),
		.SWACCESS("RW"),
		.RESVAL(6'h2)
	) u_mio_outsel6_out30(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(mio_outsel6_out30_we & regen_qs),
		.wd(mio_outsel6_out30_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[185-:6]),
		.qs(mio_outsel6_out30_qs)
	);
	prim_subreg #(
		.DW(6),
		.SWACCESS("RW"),
		.RESVAL(6'h2)
	) u_mio_outsel6_out31(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(mio_outsel6_out31_we & regen_qs),
		.wd(mio_outsel6_out31_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[191-:6]),
		.qs(mio_outsel6_out31_qs)
	);
	reg [14:0] addr_hit;
	always @(*) begin
		addr_hit = 1'sb0;
		addr_hit[0] = reg_addr == PINMUX_REGEN_OFFSET;
		addr_hit[1] = reg_addr == PINMUX_PERIPH_INSEL0_OFFSET;
		addr_hit[2] = reg_addr == PINMUX_PERIPH_INSEL1_OFFSET;
		addr_hit[3] = reg_addr == PINMUX_PERIPH_INSEL2_OFFSET;
		addr_hit[4] = reg_addr == PINMUX_PERIPH_INSEL3_OFFSET;
		addr_hit[5] = reg_addr == PINMUX_PERIPH_INSEL4_OFFSET;
		addr_hit[6] = reg_addr == PINMUX_PERIPH_INSEL5_OFFSET;
		addr_hit[7] = reg_addr == PINMUX_PERIPH_INSEL6_OFFSET;
		addr_hit[8] = reg_addr == PINMUX_MIO_OUTSEL0_OFFSET;
		addr_hit[9] = reg_addr == PINMUX_MIO_OUTSEL1_OFFSET;
		addr_hit[10] = reg_addr == PINMUX_MIO_OUTSEL2_OFFSET;
		addr_hit[11] = reg_addr == PINMUX_MIO_OUTSEL3_OFFSET;
		addr_hit[12] = reg_addr == PINMUX_MIO_OUTSEL4_OFFSET;
		addr_hit[13] = reg_addr == PINMUX_MIO_OUTSEL5_OFFSET;
		addr_hit[14] = reg_addr == PINMUX_MIO_OUTSEL6_OFFSET;
	end
	assign addrmiss = (reg_re || reg_we ? ~|addr_hit : 1'b0);
	always @(*) begin
		wr_err = 1'b0;
		if ((addr_hit[0] && reg_we) && (PINMUX_PERMIT[56+:4] != (PINMUX_PERMIT[56+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[1] && reg_we) && (PINMUX_PERMIT[52+:4] != (PINMUX_PERMIT[52+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[2] && reg_we) && (PINMUX_PERMIT[48+:4] != (PINMUX_PERMIT[48+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[3] && reg_we) && (PINMUX_PERMIT[44+:4] != (PINMUX_PERMIT[44+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[4] && reg_we) && (PINMUX_PERMIT[40+:4] != (PINMUX_PERMIT[40+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[5] && reg_we) && (PINMUX_PERMIT[36+:4] != (PINMUX_PERMIT[36+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[6] && reg_we) && (PINMUX_PERMIT[32+:4] != (PINMUX_PERMIT[32+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[7] && reg_we) && (PINMUX_PERMIT[28+:4] != (PINMUX_PERMIT[28+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[8] && reg_we) && (PINMUX_PERMIT[24+:4] != (PINMUX_PERMIT[24+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[9] && reg_we) && (PINMUX_PERMIT[20+:4] != (PINMUX_PERMIT[20+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[10] && reg_we) && (PINMUX_PERMIT[16+:4] != (PINMUX_PERMIT[16+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[11] && reg_we) && (PINMUX_PERMIT[12+:4] != (PINMUX_PERMIT[12+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[12] && reg_we) && (PINMUX_PERMIT[8+:4] != (PINMUX_PERMIT[8+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[13] && reg_we) && (PINMUX_PERMIT[4+:4] != (PINMUX_PERMIT[4+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[14] && reg_we) && (PINMUX_PERMIT[0+:4] != (PINMUX_PERMIT[0+:4] & reg_be)))
			wr_err = 1'b1;
	end
	assign regen_we = (addr_hit[0] & reg_we) & ~wr_err;
	assign regen_wd = reg_wdata[0];
	assign periph_insel0_in0_we = (addr_hit[1] & reg_we) & ~wr_err;
	assign periph_insel0_in0_wd = reg_wdata[5:0];
	assign periph_insel0_in1_we = (addr_hit[1] & reg_we) & ~wr_err;
	assign periph_insel0_in1_wd = reg_wdata[11:6];
	assign periph_insel0_in2_we = (addr_hit[1] & reg_we) & ~wr_err;
	assign periph_insel0_in2_wd = reg_wdata[17:12];
	assign periph_insel0_in3_we = (addr_hit[1] & reg_we) & ~wr_err;
	assign periph_insel0_in3_wd = reg_wdata[23:18];
	assign periph_insel0_in4_we = (addr_hit[1] & reg_we) & ~wr_err;
	assign periph_insel0_in4_wd = reg_wdata[29:24];
	assign periph_insel1_in5_we = (addr_hit[2] & reg_we) & ~wr_err;
	assign periph_insel1_in5_wd = reg_wdata[5:0];
	assign periph_insel1_in6_we = (addr_hit[2] & reg_we) & ~wr_err;
	assign periph_insel1_in6_wd = reg_wdata[11:6];
	assign periph_insel1_in7_we = (addr_hit[2] & reg_we) & ~wr_err;
	assign periph_insel1_in7_wd = reg_wdata[17:12];
	assign periph_insel1_in8_we = (addr_hit[2] & reg_we) & ~wr_err;
	assign periph_insel1_in8_wd = reg_wdata[23:18];
	assign periph_insel1_in9_we = (addr_hit[2] & reg_we) & ~wr_err;
	assign periph_insel1_in9_wd = reg_wdata[29:24];
	assign periph_insel2_in10_we = (addr_hit[3] & reg_we) & ~wr_err;
	assign periph_insel2_in10_wd = reg_wdata[5:0];
	assign periph_insel2_in11_we = (addr_hit[3] & reg_we) & ~wr_err;
	assign periph_insel2_in11_wd = reg_wdata[11:6];
	assign periph_insel2_in12_we = (addr_hit[3] & reg_we) & ~wr_err;
	assign periph_insel2_in12_wd = reg_wdata[17:12];
	assign periph_insel2_in13_we = (addr_hit[3] & reg_we) & ~wr_err;
	assign periph_insel2_in13_wd = reg_wdata[23:18];
	assign periph_insel2_in14_we = (addr_hit[3] & reg_we) & ~wr_err;
	assign periph_insel2_in14_wd = reg_wdata[29:24];
	assign periph_insel3_in15_we = (addr_hit[4] & reg_we) & ~wr_err;
	assign periph_insel3_in15_wd = reg_wdata[5:0];
	assign periph_insel3_in16_we = (addr_hit[4] & reg_we) & ~wr_err;
	assign periph_insel3_in16_wd = reg_wdata[11:6];
	assign periph_insel3_in17_we = (addr_hit[4] & reg_we) & ~wr_err;
	assign periph_insel3_in17_wd = reg_wdata[17:12];
	assign periph_insel3_in18_we = (addr_hit[4] & reg_we) & ~wr_err;
	assign periph_insel3_in18_wd = reg_wdata[23:18];
	assign periph_insel3_in19_we = (addr_hit[4] & reg_we) & ~wr_err;
	assign periph_insel3_in19_wd = reg_wdata[29:24];
	assign periph_insel4_in20_we = (addr_hit[5] & reg_we) & ~wr_err;
	assign periph_insel4_in20_wd = reg_wdata[5:0];
	assign periph_insel4_in21_we = (addr_hit[5] & reg_we) & ~wr_err;
	assign periph_insel4_in21_wd = reg_wdata[11:6];
	assign periph_insel4_in22_we = (addr_hit[5] & reg_we) & ~wr_err;
	assign periph_insel4_in22_wd = reg_wdata[17:12];
	assign periph_insel4_in23_we = (addr_hit[5] & reg_we) & ~wr_err;
	assign periph_insel4_in23_wd = reg_wdata[23:18];
	assign periph_insel4_in24_we = (addr_hit[5] & reg_we) & ~wr_err;
	assign periph_insel4_in24_wd = reg_wdata[29:24];
	assign periph_insel5_in25_we = (addr_hit[6] & reg_we) & ~wr_err;
	assign periph_insel5_in25_wd = reg_wdata[5:0];
	assign periph_insel5_in26_we = (addr_hit[6] & reg_we) & ~wr_err;
	assign periph_insel5_in26_wd = reg_wdata[11:6];
	assign periph_insel5_in27_we = (addr_hit[6] & reg_we) & ~wr_err;
	assign periph_insel5_in27_wd = reg_wdata[17:12];
	assign periph_insel5_in28_we = (addr_hit[6] & reg_we) & ~wr_err;
	assign periph_insel5_in28_wd = reg_wdata[23:18];
	assign periph_insel5_in29_we = (addr_hit[6] & reg_we) & ~wr_err;
	assign periph_insel5_in29_wd = reg_wdata[29:24];
	assign periph_insel6_in30_we = (addr_hit[7] & reg_we) & ~wr_err;
	assign periph_insel6_in30_wd = reg_wdata[5:0];
	assign periph_insel6_in31_we = (addr_hit[7] & reg_we) & ~wr_err;
	assign periph_insel6_in31_wd = reg_wdata[11:6];
	assign mio_outsel0_out0_we = (addr_hit[8] & reg_we) & ~wr_err;
	assign mio_outsel0_out0_wd = reg_wdata[5:0];
	assign mio_outsel0_out1_we = (addr_hit[8] & reg_we) & ~wr_err;
	assign mio_outsel0_out1_wd = reg_wdata[11:6];
	assign mio_outsel0_out2_we = (addr_hit[8] & reg_we) & ~wr_err;
	assign mio_outsel0_out2_wd = reg_wdata[17:12];
	assign mio_outsel0_out3_we = (addr_hit[8] & reg_we) & ~wr_err;
	assign mio_outsel0_out3_wd = reg_wdata[23:18];
	assign mio_outsel0_out4_we = (addr_hit[8] & reg_we) & ~wr_err;
	assign mio_outsel0_out4_wd = reg_wdata[29:24];
	assign mio_outsel1_out5_we = (addr_hit[9] & reg_we) & ~wr_err;
	assign mio_outsel1_out5_wd = reg_wdata[5:0];
	assign mio_outsel1_out6_we = (addr_hit[9] & reg_we) & ~wr_err;
	assign mio_outsel1_out6_wd = reg_wdata[11:6];
	assign mio_outsel1_out7_we = (addr_hit[9] & reg_we) & ~wr_err;
	assign mio_outsel1_out7_wd = reg_wdata[17:12];
	assign mio_outsel1_out8_we = (addr_hit[9] & reg_we) & ~wr_err;
	assign mio_outsel1_out8_wd = reg_wdata[23:18];
	assign mio_outsel1_out9_we = (addr_hit[9] & reg_we) & ~wr_err;
	assign mio_outsel1_out9_wd = reg_wdata[29:24];
	assign mio_outsel2_out10_we = (addr_hit[10] & reg_we) & ~wr_err;
	assign mio_outsel2_out10_wd = reg_wdata[5:0];
	assign mio_outsel2_out11_we = (addr_hit[10] & reg_we) & ~wr_err;
	assign mio_outsel2_out11_wd = reg_wdata[11:6];
	assign mio_outsel2_out12_we = (addr_hit[10] & reg_we) & ~wr_err;
	assign mio_outsel2_out12_wd = reg_wdata[17:12];
	assign mio_outsel2_out13_we = (addr_hit[10] & reg_we) & ~wr_err;
	assign mio_outsel2_out13_wd = reg_wdata[23:18];
	assign mio_outsel2_out14_we = (addr_hit[10] & reg_we) & ~wr_err;
	assign mio_outsel2_out14_wd = reg_wdata[29:24];
	assign mio_outsel3_out15_we = (addr_hit[11] & reg_we) & ~wr_err;
	assign mio_outsel3_out15_wd = reg_wdata[5:0];
	assign mio_outsel3_out16_we = (addr_hit[11] & reg_we) & ~wr_err;
	assign mio_outsel3_out16_wd = reg_wdata[11:6];
	assign mio_outsel3_out17_we = (addr_hit[11] & reg_we) & ~wr_err;
	assign mio_outsel3_out17_wd = reg_wdata[17:12];
	assign mio_outsel3_out18_we = (addr_hit[11] & reg_we) & ~wr_err;
	assign mio_outsel3_out18_wd = reg_wdata[23:18];
	assign mio_outsel3_out19_we = (addr_hit[11] & reg_we) & ~wr_err;
	assign mio_outsel3_out19_wd = reg_wdata[29:24];
	assign mio_outsel4_out20_we = (addr_hit[12] & reg_we) & ~wr_err;
	assign mio_outsel4_out20_wd = reg_wdata[5:0];
	assign mio_outsel4_out21_we = (addr_hit[12] & reg_we) & ~wr_err;
	assign mio_outsel4_out21_wd = reg_wdata[11:6];
	assign mio_outsel4_out22_we = (addr_hit[12] & reg_we) & ~wr_err;
	assign mio_outsel4_out22_wd = reg_wdata[17:12];
	assign mio_outsel4_out23_we = (addr_hit[12] & reg_we) & ~wr_err;
	assign mio_outsel4_out23_wd = reg_wdata[23:18];
	assign mio_outsel4_out24_we = (addr_hit[12] & reg_we) & ~wr_err;
	assign mio_outsel4_out24_wd = reg_wdata[29:24];
	assign mio_outsel5_out25_we = (addr_hit[13] & reg_we) & ~wr_err;
	assign mio_outsel5_out25_wd = reg_wdata[5:0];
	assign mio_outsel5_out26_we = (addr_hit[13] & reg_we) & ~wr_err;
	assign mio_outsel5_out26_wd = reg_wdata[11:6];
	assign mio_outsel5_out27_we = (addr_hit[13] & reg_we) & ~wr_err;
	assign mio_outsel5_out27_wd = reg_wdata[17:12];
	assign mio_outsel5_out28_we = (addr_hit[13] & reg_we) & ~wr_err;
	assign mio_outsel5_out28_wd = reg_wdata[23:18];
	assign mio_outsel5_out29_we = (addr_hit[13] & reg_we) & ~wr_err;
	assign mio_outsel5_out29_wd = reg_wdata[29:24];
	assign mio_outsel6_out30_we = (addr_hit[14] & reg_we) & ~wr_err;
	assign mio_outsel6_out30_wd = reg_wdata[5:0];
	assign mio_outsel6_out31_we = (addr_hit[14] & reg_we) & ~wr_err;
	assign mio_outsel6_out31_wd = reg_wdata[11:6];
	always @(*) begin
		reg_rdata_next = 1'sb0;
		case (1'b1)
			addr_hit[0]: reg_rdata_next[0] = regen_qs;
			addr_hit[1]: begin
				reg_rdata_next[5:0] = periph_insel0_in0_qs;
				reg_rdata_next[11:6] = periph_insel0_in1_qs;
				reg_rdata_next[17:12] = periph_insel0_in2_qs;
				reg_rdata_next[23:18] = periph_insel0_in3_qs;
				reg_rdata_next[29:24] = periph_insel0_in4_qs;
			end
			addr_hit[2]: begin
				reg_rdata_next[5:0] = periph_insel1_in5_qs;
				reg_rdata_next[11:6] = periph_insel1_in6_qs;
				reg_rdata_next[17:12] = periph_insel1_in7_qs;
				reg_rdata_next[23:18] = periph_insel1_in8_qs;
				reg_rdata_next[29:24] = periph_insel1_in9_qs;
			end
			addr_hit[3]: begin
				reg_rdata_next[5:0] = periph_insel2_in10_qs;
				reg_rdata_next[11:6] = periph_insel2_in11_qs;
				reg_rdata_next[17:12] = periph_insel2_in12_qs;
				reg_rdata_next[23:18] = periph_insel2_in13_qs;
				reg_rdata_next[29:24] = periph_insel2_in14_qs;
			end
			addr_hit[4]: begin
				reg_rdata_next[5:0] = periph_insel3_in15_qs;
				reg_rdata_next[11:6] = periph_insel3_in16_qs;
				reg_rdata_next[17:12] = periph_insel3_in17_qs;
				reg_rdata_next[23:18] = periph_insel3_in18_qs;
				reg_rdata_next[29:24] = periph_insel3_in19_qs;
			end
			addr_hit[5]: begin
				reg_rdata_next[5:0] = periph_insel4_in20_qs;
				reg_rdata_next[11:6] = periph_insel4_in21_qs;
				reg_rdata_next[17:12] = periph_insel4_in22_qs;
				reg_rdata_next[23:18] = periph_insel4_in23_qs;
				reg_rdata_next[29:24] = periph_insel4_in24_qs;
			end
			addr_hit[6]: begin
				reg_rdata_next[5:0] = periph_insel5_in25_qs;
				reg_rdata_next[11:6] = periph_insel5_in26_qs;
				reg_rdata_next[17:12] = periph_insel5_in27_qs;
				reg_rdata_next[23:18] = periph_insel5_in28_qs;
				reg_rdata_next[29:24] = periph_insel5_in29_qs;
			end
			addr_hit[7]: begin
				reg_rdata_next[5:0] = periph_insel6_in30_qs;
				reg_rdata_next[11:6] = periph_insel6_in31_qs;
			end
			addr_hit[8]: begin
				reg_rdata_next[5:0] = mio_outsel0_out0_qs;
				reg_rdata_next[11:6] = mio_outsel0_out1_qs;
				reg_rdata_next[17:12] = mio_outsel0_out2_qs;
				reg_rdata_next[23:18] = mio_outsel0_out3_qs;
				reg_rdata_next[29:24] = mio_outsel0_out4_qs;
			end
			addr_hit[9]: begin
				reg_rdata_next[5:0] = mio_outsel1_out5_qs;
				reg_rdata_next[11:6] = mio_outsel1_out6_qs;
				reg_rdata_next[17:12] = mio_outsel1_out7_qs;
				reg_rdata_next[23:18] = mio_outsel1_out8_qs;
				reg_rdata_next[29:24] = mio_outsel1_out9_qs;
			end
			addr_hit[10]: begin
				reg_rdata_next[5:0] = mio_outsel2_out10_qs;
				reg_rdata_next[11:6] = mio_outsel2_out11_qs;
				reg_rdata_next[17:12] = mio_outsel2_out12_qs;
				reg_rdata_next[23:18] = mio_outsel2_out13_qs;
				reg_rdata_next[29:24] = mio_outsel2_out14_qs;
			end
			addr_hit[11]: begin
				reg_rdata_next[5:0] = mio_outsel3_out15_qs;
				reg_rdata_next[11:6] = mio_outsel3_out16_qs;
				reg_rdata_next[17:12] = mio_outsel3_out17_qs;
				reg_rdata_next[23:18] = mio_outsel3_out18_qs;
				reg_rdata_next[29:24] = mio_outsel3_out19_qs;
			end
			addr_hit[12]: begin
				reg_rdata_next[5:0] = mio_outsel4_out20_qs;
				reg_rdata_next[11:6] = mio_outsel4_out21_qs;
				reg_rdata_next[17:12] = mio_outsel4_out22_qs;
				reg_rdata_next[23:18] = mio_outsel4_out23_qs;
				reg_rdata_next[29:24] = mio_outsel4_out24_qs;
			end
			addr_hit[13]: begin
				reg_rdata_next[5:0] = mio_outsel5_out25_qs;
				reg_rdata_next[11:6] = mio_outsel5_out26_qs;
				reg_rdata_next[17:12] = mio_outsel5_out27_qs;
				reg_rdata_next[23:18] = mio_outsel5_out28_qs;
				reg_rdata_next[29:24] = mio_outsel5_out29_qs;
			end
			addr_hit[14]: begin
				reg_rdata_next[5:0] = mio_outsel6_out30_qs;
				reg_rdata_next[11:6] = mio_outsel6_out31_qs;
			end
			default: reg_rdata_next = 1'sb1;
		endcase
	end
endmodule
