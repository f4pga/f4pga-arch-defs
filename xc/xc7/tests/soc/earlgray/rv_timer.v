module rv_timer (
	clk_i,
	rst_ni,
	tl_i,
	tl_o,
	intr_timer_expired_0_0_o
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
	output wire intr_timer_expired_0_0_o;
	localparam signed [31:0] N_HARTS = 1;
	localparam signed [31:0] N_TIMERS = 1;
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
	wire [154:0] reg2hw;
	wire [67:0] hw2reg;
	wire [N_HARTS - 1:0] active;
	wire [((2 - N_HARTS) * 12) + (((N_HARTS - 1) * 12) - 1):(N_HARTS - 1) * 12] prescaler;
	wire [((2 - N_HARTS) * 8) + (((N_HARTS - 1) * 8) - 1):(N_HARTS - 1) * 8] step;
	wire [N_HARTS - 1:0] tick;
	wire [63:0] mtime_d [0:N_HARTS - 1];
	wire [63:0] mtime [0:N_HARTS - 1];
	wire [((((((2 - N_HARTS) * (2 - N_TIMERS)) + (((N_TIMERS - 1) + ((N_HARTS - 1) * (2 - N_TIMERS))) - 1)) - ((N_TIMERS - 1) + ((N_HARTS - 1) * (2 - N_TIMERS)))) + 1) * 64) + ((((N_TIMERS - 1) + ((N_HARTS - 1) * (2 - N_TIMERS))) * 64) - 1):((N_TIMERS - 1) + ((N_HARTS - 1) * (2 - N_TIMERS))) * 64] mtimecmp;
	wire mtimecmp_update [0:N_HARTS - 1][0:N_TIMERS - 1];
	wire [(N_HARTS * N_TIMERS) - 1:0] intr_timer_set;
	wire [(N_HARTS * N_TIMERS) - 1:0] intr_timer_en;
	wire [(N_HARTS * N_TIMERS) - 1:0] intr_timer_test_q;
	wire [N_HARTS - 1:0] intr_timer_test_qe;
	wire [(N_HARTS * N_TIMERS) - 1:0] intr_timer_state_q;
	wire [N_HARTS - 1:0] intr_timer_state_de;
	wire [(N_HARTS * N_TIMERS) - 1:0] intr_timer_state_d;
	wire [(N_HARTS * N_TIMERS) - 1:0] intr_out;
	assign active[0] = reg2hw[154];
	assign prescaler = reg2hw[153-:12];
	assign step = reg2hw[141-:8];
	assign hw2reg[2] = tick[0];
	assign hw2reg[35] = tick[0];
	assign hw2reg[34-:32] = mtime_d[0][63:32];
	assign hw2reg[67-:32] = mtime_d[0][31:0];
	assign mtime[0] = {reg2hw[101-:32], reg2hw[133-:32]};
	assign mtimecmp = {reg2hw[36-:32], reg2hw[69-:32]};
	assign mtimecmp_update[0][0] = reg2hw[4] | reg2hw[37];
	assign intr_timer_expired_0_0_o = intr_out[0];
	assign intr_timer_en = reg2hw[3];
	assign intr_timer_state_q = reg2hw[2];
	assign intr_timer_test_q = reg2hw[1];
	assign intr_timer_test_qe = reg2hw[0];
	assign hw2reg[0] = intr_timer_state_de | mtimecmp_update[0][0];
	assign hw2reg[1] = intr_timer_state_d & ~mtimecmp_update[0][0];
	generate
		genvar h;
		for (h = 0; h < N_HARTS; h = h + 1) begin : gen_harts
			prim_intr_hw #(.Width(N_TIMERS)) u_intr_hw(
				.event_intr_i(intr_timer_set),
				.reg2hw_intr_enable_q_i(intr_timer_en[h * N_TIMERS+:N_TIMERS]),
				.reg2hw_intr_test_q_i(intr_timer_test_q[h * N_TIMERS+:N_TIMERS]),
				.reg2hw_intr_test_qe_i(intr_timer_test_qe[h]),
				.reg2hw_intr_state_q_i(intr_timer_state_q[h * N_TIMERS+:N_TIMERS]),
				.hw2reg_intr_state_de_o(intr_timer_state_de),
				.hw2reg_intr_state_d_o(intr_timer_state_d[h * N_TIMERS+:N_TIMERS]),
				.intr_o(intr_out[h * N_TIMERS+:N_TIMERS])
			);
			timer_core #(.N(N_TIMERS)) u_core(
				.clk_i(clk_i),
				.rst_ni(rst_ni),
				.active(active[h]),
				.prescaler(prescaler[h * 12+:12]),
				.step(step[h * 8+:8]),
				.tick(tick[h]),
				.mtime_d(mtime_d[h]),
				.mtime(mtime[h]),
				.mtimecmp(mtimecmp[64 * ((N_TIMERS - 1) + (h * (2 - N_TIMERS)))+:64 * (2 - N_TIMERS)]),
				.intr(intr_timer_set[h * N_TIMERS+:N_TIMERS])
			);
		end
	endgenerate
	rv_timer_reg_top u_reg(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.tl_i(tl_i),
		.tl_o(tl_o),
		.reg2hw(reg2hw),
		.hw2reg(hw2reg),
		.devmode_i(1'b1)
	);
endmodule
