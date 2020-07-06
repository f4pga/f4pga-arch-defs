module nmi_gen_reg_top (
	clk_i,
	rst_ni,
	tl_i,
	tl_o,
	reg2hw,
	hw2reg,
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
	output wire [15:0] reg2hw;
	input wire [7:0] hw2reg;
	input devmode_i;
	parameter [3:0] NMI_GEN_INTR_STATE_OFFSET = 4'h 0;
	parameter [3:0] NMI_GEN_INTR_ENABLE_OFFSET = 4'h 4;
	parameter [3:0] NMI_GEN_INTR_TEST_OFFSET = 4'h 8;
	parameter [11:0] NMI_GEN_PERMIT = {4'b 0001, 4'b 0001, 4'b 0001};
	localparam NMI_GEN_INTR_STATE = 0;
	localparam NMI_GEN_INTR_ENABLE = 1;
	localparam NMI_GEN_INTR_TEST = 2;
	localparam signed [31:0] AW = 4;
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
	wire intr_state_esc0_qs;
	wire intr_state_esc0_wd;
	wire intr_state_esc0_we;
	wire intr_state_esc1_qs;
	wire intr_state_esc1_wd;
	wire intr_state_esc1_we;
	wire intr_state_esc2_qs;
	wire intr_state_esc2_wd;
	wire intr_state_esc2_we;
	wire intr_state_esc3_qs;
	wire intr_state_esc3_wd;
	wire intr_state_esc3_we;
	wire intr_enable_esc0_qs;
	wire intr_enable_esc0_wd;
	wire intr_enable_esc0_we;
	wire intr_enable_esc1_qs;
	wire intr_enable_esc1_wd;
	wire intr_enable_esc1_we;
	wire intr_enable_esc2_qs;
	wire intr_enable_esc2_wd;
	wire intr_enable_esc2_we;
	wire intr_enable_esc3_qs;
	wire intr_enable_esc3_wd;
	wire intr_enable_esc3_we;
	wire intr_test_esc0_wd;
	wire intr_test_esc0_we;
	wire intr_test_esc1_wd;
	wire intr_test_esc1_we;
	wire intr_test_esc2_wd;
	wire intr_test_esc2_we;
	wire intr_test_esc3_wd;
	wire intr_test_esc3_we;
	prim_subreg #(
		.DW(1),
		.SWACCESS("W1C"),
		.RESVAL(1'h0)
	) u_intr_state_esc0(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(intr_state_esc0_we),
		.wd(intr_state_esc0_wd),
		.de(hw2reg[6]),
		.d(hw2reg[7]),
		.qe(),
		.q(reg2hw[15]),
		.qs(intr_state_esc0_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("W1C"),
		.RESVAL(1'h0)
	) u_intr_state_esc1(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(intr_state_esc1_we),
		.wd(intr_state_esc1_wd),
		.de(hw2reg[4]),
		.d(hw2reg[5]),
		.qe(),
		.q(reg2hw[14]),
		.qs(intr_state_esc1_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("W1C"),
		.RESVAL(1'h0)
	) u_intr_state_esc2(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(intr_state_esc2_we),
		.wd(intr_state_esc2_wd),
		.de(hw2reg[2]),
		.d(hw2reg[3]),
		.qe(),
		.q(reg2hw[13]),
		.qs(intr_state_esc2_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("W1C"),
		.RESVAL(1'h0)
	) u_intr_state_esc3(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(intr_state_esc3_we),
		.wd(intr_state_esc3_wd),
		.de(hw2reg[0]),
		.d(hw2reg[1]),
		.qe(),
		.q(reg2hw[12]),
		.qs(intr_state_esc3_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_intr_enable_esc0(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(intr_enable_esc0_we),
		.wd(intr_enable_esc0_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[11]),
		.qs(intr_enable_esc0_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_intr_enable_esc1(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(intr_enable_esc1_we),
		.wd(intr_enable_esc1_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[10]),
		.qs(intr_enable_esc1_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_intr_enable_esc2(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(intr_enable_esc2_we),
		.wd(intr_enable_esc2_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[9]),
		.qs(intr_enable_esc2_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_intr_enable_esc3(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(intr_enable_esc3_we),
		.wd(intr_enable_esc3_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[8]),
		.qs(intr_enable_esc3_qs)
	);
	prim_subreg_ext #(.DW(1)) u_intr_test_esc0(
		.re(1'b0),
		.we(intr_test_esc0_we),
		.wd(intr_test_esc0_wd),
		.d(1'sb0),
		.qre(),
		.qe(reg2hw[6]),
		.q(reg2hw[7]),
		.qs()
	);
	prim_subreg_ext #(.DW(1)) u_intr_test_esc1(
		.re(1'b0),
		.we(intr_test_esc1_we),
		.wd(intr_test_esc1_wd),
		.d(1'sb0),
		.qre(),
		.qe(reg2hw[4]),
		.q(reg2hw[5]),
		.qs()
	);
	prim_subreg_ext #(.DW(1)) u_intr_test_esc2(
		.re(1'b0),
		.we(intr_test_esc2_we),
		.wd(intr_test_esc2_wd),
		.d(1'sb0),
		.qre(),
		.qe(reg2hw[2]),
		.q(reg2hw[3]),
		.qs()
	);
	prim_subreg_ext #(.DW(1)) u_intr_test_esc3(
		.re(1'b0),
		.we(intr_test_esc3_we),
		.wd(intr_test_esc3_wd),
		.d(1'sb0),
		.qre(),
		.qe(reg2hw[0]),
		.q(reg2hw[1]),
		.qs()
	);
	reg [2:0] addr_hit;
	always @(*) begin
		addr_hit = 1'sb0;
		addr_hit[0] = reg_addr == NMI_GEN_INTR_STATE_OFFSET;
		addr_hit[1] = reg_addr == NMI_GEN_INTR_ENABLE_OFFSET;
		addr_hit[2] = reg_addr == NMI_GEN_INTR_TEST_OFFSET;
	end
	assign addrmiss = (reg_re || reg_we ? ~|addr_hit : 1'b0);
	always @(*) begin
		wr_err = 1'b0;
		if ((addr_hit[0] && reg_we) && (NMI_GEN_PERMIT[8+:4] != (NMI_GEN_PERMIT[8+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[1] && reg_we) && (NMI_GEN_PERMIT[4+:4] != (NMI_GEN_PERMIT[4+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[2] && reg_we) && (NMI_GEN_PERMIT[0+:4] != (NMI_GEN_PERMIT[0+:4] & reg_be)))
			wr_err = 1'b1;
	end
	assign intr_state_esc0_we = (addr_hit[0] & reg_we) & ~wr_err;
	assign intr_state_esc0_wd = reg_wdata[0];
	assign intr_state_esc1_we = (addr_hit[0] & reg_we) & ~wr_err;
	assign intr_state_esc1_wd = reg_wdata[1];
	assign intr_state_esc2_we = (addr_hit[0] & reg_we) & ~wr_err;
	assign intr_state_esc2_wd = reg_wdata[2];
	assign intr_state_esc3_we = (addr_hit[0] & reg_we) & ~wr_err;
	assign intr_state_esc3_wd = reg_wdata[3];
	assign intr_enable_esc0_we = (addr_hit[1] & reg_we) & ~wr_err;
	assign intr_enable_esc0_wd = reg_wdata[0];
	assign intr_enable_esc1_we = (addr_hit[1] & reg_we) & ~wr_err;
	assign intr_enable_esc1_wd = reg_wdata[1];
	assign intr_enable_esc2_we = (addr_hit[1] & reg_we) & ~wr_err;
	assign intr_enable_esc2_wd = reg_wdata[2];
	assign intr_enable_esc3_we = (addr_hit[1] & reg_we) & ~wr_err;
	assign intr_enable_esc3_wd = reg_wdata[3];
	assign intr_test_esc0_we = (addr_hit[2] & reg_we) & ~wr_err;
	assign intr_test_esc0_wd = reg_wdata[0];
	assign intr_test_esc1_we = (addr_hit[2] & reg_we) & ~wr_err;
	assign intr_test_esc1_wd = reg_wdata[1];
	assign intr_test_esc2_we = (addr_hit[2] & reg_we) & ~wr_err;
	assign intr_test_esc2_wd = reg_wdata[2];
	assign intr_test_esc3_we = (addr_hit[2] & reg_we) & ~wr_err;
	assign intr_test_esc3_wd = reg_wdata[3];
	always @(*) begin
		reg_rdata_next = 1'sb0;
		case (1'b1)
			addr_hit[0]: begin
				reg_rdata_next[0] = intr_state_esc0_qs;
				reg_rdata_next[1] = intr_state_esc1_qs;
				reg_rdata_next[2] = intr_state_esc2_qs;
				reg_rdata_next[3] = intr_state_esc3_qs;
			end
			addr_hit[1]: begin
				reg_rdata_next[0] = intr_enable_esc0_qs;
				reg_rdata_next[1] = intr_enable_esc1_qs;
				reg_rdata_next[2] = intr_enable_esc2_qs;
				reg_rdata_next[3] = intr_enable_esc3_qs;
			end
			addr_hit[2]: begin
				reg_rdata_next[0] = 1'sb0;
				reg_rdata_next[1] = 1'sb0;
				reg_rdata_next[2] = 1'sb0;
				reg_rdata_next[3] = 1'sb0;
			end
			default: reg_rdata_next = 1'sb1;
		endcase
	end
endmodule
