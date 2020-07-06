module rv_timer_reg_top (
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
	output wire [154:0] reg2hw;
	input wire [67:0] hw2reg;
	input devmode_i;
	parameter signed [31:0] N_HARTS = 1;
	parameter signed [31:0] N_TIMERS = 1;
	parameter [8:0] RV_TIMER_CTRL_OFFSET = 9'h 0;
	parameter [8:0] RV_TIMER_CFG0_OFFSET = 9'h 100;
	parameter [8:0] RV_TIMER_TIMER_V_LOWER0_OFFSET = 9'h 104;
	parameter [8:0] RV_TIMER_TIMER_V_UPPER0_OFFSET = 9'h 108;
	parameter [8:0] RV_TIMER_COMPARE_LOWER0_0_OFFSET = 9'h 10c;
	parameter [8:0] RV_TIMER_COMPARE_UPPER0_0_OFFSET = 9'h 110;
	parameter [8:0] RV_TIMER_INTR_ENABLE0_OFFSET = 9'h 114;
	parameter [8:0] RV_TIMER_INTR_STATE0_OFFSET = 9'h 118;
	parameter [8:0] RV_TIMER_INTR_TEST0_OFFSET = 9'h 11c;
	parameter [35:0] RV_TIMER_PERMIT = {4'b 0001, 4'b 0111, 4'b 1111, 4'b 1111, 4'b 1111, 4'b 1111, 4'b 0001, 4'b 0001, 4'b 0001};
	localparam RV_TIMER_CTRL = 0;
	localparam RV_TIMER_CFG0 = 1;
	localparam RV_TIMER_TIMER_V_LOWER0 = 2;
	localparam RV_TIMER_TIMER_V_UPPER0 = 3;
	localparam RV_TIMER_COMPARE_LOWER0_0 = 4;
	localparam RV_TIMER_COMPARE_UPPER0_0 = 5;
	localparam RV_TIMER_INTR_ENABLE0 = 6;
	localparam RV_TIMER_INTR_STATE0 = 7;
	localparam RV_TIMER_INTR_TEST0 = 8;
	localparam signed [31:0] AW = 9;
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
	wire ctrl_qs;
	wire ctrl_wd;
	wire ctrl_we;
	wire [11:0] cfg0_prescale_qs;
	wire [11:0] cfg0_prescale_wd;
	wire cfg0_prescale_we;
	wire [7:0] cfg0_step_qs;
	wire [7:0] cfg0_step_wd;
	wire cfg0_step_we;
	wire [31:0] timer_v_lower0_qs;
	wire [31:0] timer_v_lower0_wd;
	wire timer_v_lower0_we;
	wire [31:0] timer_v_upper0_qs;
	wire [31:0] timer_v_upper0_wd;
	wire timer_v_upper0_we;
	wire [31:0] compare_lower0_0_qs;
	wire [31:0] compare_lower0_0_wd;
	wire compare_lower0_0_we;
	wire [31:0] compare_upper0_0_qs;
	wire [31:0] compare_upper0_0_wd;
	wire compare_upper0_0_we;
	wire intr_enable0_qs;
	wire intr_enable0_wd;
	wire intr_enable0_we;
	wire intr_state0_qs;
	wire intr_state0_wd;
	wire intr_state0_we;
	wire intr_test0_wd;
	wire intr_test0_we;
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_ctrl(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(ctrl_we),
		.wd(ctrl_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[154]),
		.qs(ctrl_qs)
	);
	prim_subreg #(
		.DW(12),
		.SWACCESS("RW"),
		.RESVAL(12'h0)
	) u_cfg0_prescale(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(cfg0_prescale_we),
		.wd(cfg0_prescale_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[153-:12]),
		.qs(cfg0_prescale_qs)
	);
	prim_subreg #(
		.DW(8),
		.SWACCESS("RW"),
		.RESVAL(8'h1)
	) u_cfg0_step(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(cfg0_step_we),
		.wd(cfg0_step_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[141-:8]),
		.qs(cfg0_step_qs)
	);
	prim_subreg #(
		.DW(32),
		.SWACCESS("RW"),
		.RESVAL(32'h0)
	) u_timer_v_lower0(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(timer_v_lower0_we),
		.wd(timer_v_lower0_wd),
		.de(hw2reg[35]),
		.d(hw2reg[67-:32]),
		.qe(),
		.q(reg2hw[133-:32]),
		.qs(timer_v_lower0_qs)
	);
	prim_subreg #(
		.DW(32),
		.SWACCESS("RW"),
		.RESVAL(32'h0)
	) u_timer_v_upper0(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(timer_v_upper0_we),
		.wd(timer_v_upper0_wd),
		.de(hw2reg[2]),
		.d(hw2reg[34-:32]),
		.qe(),
		.q(reg2hw[101-:32]),
		.qs(timer_v_upper0_qs)
	);
	prim_subreg #(
		.DW(32),
		.SWACCESS("RW"),
		.RESVAL(32'hffffffff)
	) u_compare_lower0_0(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(compare_lower0_0_we),
		.wd(compare_lower0_0_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(reg2hw[37]),
		.q(reg2hw[69-:32]),
		.qs(compare_lower0_0_qs)
	);
	prim_subreg #(
		.DW(32),
		.SWACCESS("RW"),
		.RESVAL(32'hffffffff)
	) u_compare_upper0_0(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(compare_upper0_0_we),
		.wd(compare_upper0_0_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(reg2hw[4]),
		.q(reg2hw[36-:32]),
		.qs(compare_upper0_0_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_intr_enable0(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(intr_enable0_we),
		.wd(intr_enable0_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[3]),
		.qs(intr_enable0_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("W1C"),
		.RESVAL(1'h0)
	) u_intr_state0(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(intr_state0_we),
		.wd(intr_state0_wd),
		.de(hw2reg[0]),
		.d(hw2reg[1]),
		.qe(),
		.q(reg2hw[2]),
		.qs(intr_state0_qs)
	);
	prim_subreg_ext #(.DW(1)) u_intr_test0(
		.re(1'b0),
		.we(intr_test0_we),
		.wd(intr_test0_wd),
		.d(1'sb0),
		.qre(),
		.qe(reg2hw[0]),
		.q(reg2hw[1]),
		.qs()
	);
	reg [8:0] addr_hit;
	always @(*) begin
		addr_hit = 1'sb0;
		addr_hit[0] = reg_addr == RV_TIMER_CTRL_OFFSET;
		addr_hit[1] = reg_addr == RV_TIMER_CFG0_OFFSET;
		addr_hit[2] = reg_addr == RV_TIMER_TIMER_V_LOWER0_OFFSET;
		addr_hit[3] = reg_addr == RV_TIMER_TIMER_V_UPPER0_OFFSET;
		addr_hit[4] = reg_addr == RV_TIMER_COMPARE_LOWER0_0_OFFSET;
		addr_hit[5] = reg_addr == RV_TIMER_COMPARE_UPPER0_0_OFFSET;
		addr_hit[6] = reg_addr == RV_TIMER_INTR_ENABLE0_OFFSET;
		addr_hit[7] = reg_addr == RV_TIMER_INTR_STATE0_OFFSET;
		addr_hit[8] = reg_addr == RV_TIMER_INTR_TEST0_OFFSET;
	end
	assign addrmiss = (reg_re || reg_we ? ~|addr_hit : 1'b0);
	always @(*) begin
		wr_err = 1'b0;
		if ((addr_hit[0] && reg_we) && (RV_TIMER_PERMIT[32+:4] != (RV_TIMER_PERMIT[32+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[1] && reg_we) && (RV_TIMER_PERMIT[28+:4] != (RV_TIMER_PERMIT[28+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[2] && reg_we) && (RV_TIMER_PERMIT[24+:4] != (RV_TIMER_PERMIT[24+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[3] && reg_we) && (RV_TIMER_PERMIT[20+:4] != (RV_TIMER_PERMIT[20+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[4] && reg_we) && (RV_TIMER_PERMIT[16+:4] != (RV_TIMER_PERMIT[16+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[5] && reg_we) && (RV_TIMER_PERMIT[12+:4] != (RV_TIMER_PERMIT[12+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[6] && reg_we) && (RV_TIMER_PERMIT[8+:4] != (RV_TIMER_PERMIT[8+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[7] && reg_we) && (RV_TIMER_PERMIT[4+:4] != (RV_TIMER_PERMIT[4+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[8] && reg_we) && (RV_TIMER_PERMIT[0+:4] != (RV_TIMER_PERMIT[0+:4] & reg_be)))
			wr_err = 1'b1;
	end
	assign ctrl_we = (addr_hit[0] & reg_we) & ~wr_err;
	assign ctrl_wd = reg_wdata[0];
	assign cfg0_prescale_we = (addr_hit[1] & reg_we) & ~wr_err;
	assign cfg0_prescale_wd = reg_wdata[11:0];
	assign cfg0_step_we = (addr_hit[1] & reg_we) & ~wr_err;
	assign cfg0_step_wd = reg_wdata[23:16];
	assign timer_v_lower0_we = (addr_hit[2] & reg_we) & ~wr_err;
	assign timer_v_lower0_wd = reg_wdata[31:0];
	assign timer_v_upper0_we = (addr_hit[3] & reg_we) & ~wr_err;
	assign timer_v_upper0_wd = reg_wdata[31:0];
	assign compare_lower0_0_we = (addr_hit[4] & reg_we) & ~wr_err;
	assign compare_lower0_0_wd = reg_wdata[31:0];
	assign compare_upper0_0_we = (addr_hit[5] & reg_we) & ~wr_err;
	assign compare_upper0_0_wd = reg_wdata[31:0];
	assign intr_enable0_we = (addr_hit[6] & reg_we) & ~wr_err;
	assign intr_enable0_wd = reg_wdata[0];
	assign intr_state0_we = (addr_hit[7] & reg_we) & ~wr_err;
	assign intr_state0_wd = reg_wdata[0];
	assign intr_test0_we = (addr_hit[8] & reg_we) & ~wr_err;
	assign intr_test0_wd = reg_wdata[0];
	always @(*) begin
		reg_rdata_next = 1'sb0;
		case (1'b1)
			addr_hit[0]: reg_rdata_next[0] = ctrl_qs;
			addr_hit[1]: begin
				reg_rdata_next[11:0] = cfg0_prescale_qs;
				reg_rdata_next[23:16] = cfg0_step_qs;
			end
			addr_hit[2]: reg_rdata_next[31:0] = timer_v_lower0_qs;
			addr_hit[3]: reg_rdata_next[31:0] = timer_v_upper0_qs;
			addr_hit[4]: reg_rdata_next[31:0] = compare_lower0_0_qs;
			addr_hit[5]: reg_rdata_next[31:0] = compare_upper0_0_qs;
			addr_hit[6]: reg_rdata_next[0] = intr_enable0_qs;
			addr_hit[7]: reg_rdata_next[0] = intr_state0_qs;
			addr_hit[8]: reg_rdata_next[0] = 1'sb0;
			default: reg_rdata_next = 1'sb1;
		endcase
	end
endmodule
