module alert_handler_reg_top (
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
	output wire [828:0] reg2hw;
	input wire [229:0] hw2reg;
	input devmode_i;
	parameter signed [31:0] NAlerts = 1;
	parameter signed [31:0] EscCntDw = 32;
	parameter signed [31:0] AccuCntDw = 16;
	parameter signed [31:0] LfsrSeed = 2147483647;
	parameter [NAlerts - 1:0] AsyncOn = 1'b0;
	parameter signed [31:0] N_CLASSES = 4;
	parameter signed [31:0] N_ESC_SEV = 4;
	parameter signed [31:0] N_PHASES = 4;
	parameter signed [31:0] N_LOC_ALERT = 4;
	parameter signed [31:0] PING_CNT_DW = 24;
	parameter signed [31:0] PHASE_DW = 2;
	parameter signed [31:0] CLASS_DW = 2;
	parameter [7:0] ALERT_HANDLER_INTR_STATE_OFFSET = 8'h 0;
	parameter [7:0] ALERT_HANDLER_INTR_ENABLE_OFFSET = 8'h 4;
	parameter [7:0] ALERT_HANDLER_INTR_TEST_OFFSET = 8'h 8;
	parameter [7:0] ALERT_HANDLER_REGEN_OFFSET = 8'h c;
	parameter [7:0] ALERT_HANDLER_PING_TIMEOUT_CYC_OFFSET = 8'h 10;
	parameter [7:0] ALERT_HANDLER_ALERT_EN_OFFSET = 8'h 14;
	parameter [7:0] ALERT_HANDLER_ALERT_CLASS_OFFSET = 8'h 18;
	parameter [7:0] ALERT_HANDLER_ALERT_CAUSE_OFFSET = 8'h 1c;
	parameter [7:0] ALERT_HANDLER_LOC_ALERT_EN_OFFSET = 8'h 20;
	parameter [7:0] ALERT_HANDLER_LOC_ALERT_CLASS_OFFSET = 8'h 24;
	parameter [7:0] ALERT_HANDLER_LOC_ALERT_CAUSE_OFFSET = 8'h 28;
	parameter [7:0] ALERT_HANDLER_CLASSA_CTRL_OFFSET = 8'h 2c;
	parameter [7:0] ALERT_HANDLER_CLASSA_CLREN_OFFSET = 8'h 30;
	parameter [7:0] ALERT_HANDLER_CLASSA_CLR_OFFSET = 8'h 34;
	parameter [7:0] ALERT_HANDLER_CLASSA_ACCUM_CNT_OFFSET = 8'h 38;
	parameter [7:0] ALERT_HANDLER_CLASSA_ACCUM_THRESH_OFFSET = 8'h 3c;
	parameter [7:0] ALERT_HANDLER_CLASSA_TIMEOUT_CYC_OFFSET = 8'h 40;
	parameter [7:0] ALERT_HANDLER_CLASSA_PHASE0_CYC_OFFSET = 8'h 44;
	parameter [7:0] ALERT_HANDLER_CLASSA_PHASE1_CYC_OFFSET = 8'h 48;
	parameter [7:0] ALERT_HANDLER_CLASSA_PHASE2_CYC_OFFSET = 8'h 4c;
	parameter [7:0] ALERT_HANDLER_CLASSA_PHASE3_CYC_OFFSET = 8'h 50;
	parameter [7:0] ALERT_HANDLER_CLASSA_ESC_CNT_OFFSET = 8'h 54;
	parameter [7:0] ALERT_HANDLER_CLASSA_STATE_OFFSET = 8'h 58;
	parameter [7:0] ALERT_HANDLER_CLASSB_CTRL_OFFSET = 8'h 5c;
	parameter [7:0] ALERT_HANDLER_CLASSB_CLREN_OFFSET = 8'h 60;
	parameter [7:0] ALERT_HANDLER_CLASSB_CLR_OFFSET = 8'h 64;
	parameter [7:0] ALERT_HANDLER_CLASSB_ACCUM_CNT_OFFSET = 8'h 68;
	parameter [7:0] ALERT_HANDLER_CLASSB_ACCUM_THRESH_OFFSET = 8'h 6c;
	parameter [7:0] ALERT_HANDLER_CLASSB_TIMEOUT_CYC_OFFSET = 8'h 70;
	parameter [7:0] ALERT_HANDLER_CLASSB_PHASE0_CYC_OFFSET = 8'h 74;
	parameter [7:0] ALERT_HANDLER_CLASSB_PHASE1_CYC_OFFSET = 8'h 78;
	parameter [7:0] ALERT_HANDLER_CLASSB_PHASE2_CYC_OFFSET = 8'h 7c;
	parameter [7:0] ALERT_HANDLER_CLASSB_PHASE3_CYC_OFFSET = 8'h 80;
	parameter [7:0] ALERT_HANDLER_CLASSB_ESC_CNT_OFFSET = 8'h 84;
	parameter [7:0] ALERT_HANDLER_CLASSB_STATE_OFFSET = 8'h 88;
	parameter [7:0] ALERT_HANDLER_CLASSC_CTRL_OFFSET = 8'h 8c;
	parameter [7:0] ALERT_HANDLER_CLASSC_CLREN_OFFSET = 8'h 90;
	parameter [7:0] ALERT_HANDLER_CLASSC_CLR_OFFSET = 8'h 94;
	parameter [7:0] ALERT_HANDLER_CLASSC_ACCUM_CNT_OFFSET = 8'h 98;
	parameter [7:0] ALERT_HANDLER_CLASSC_ACCUM_THRESH_OFFSET = 8'h 9c;
	parameter [7:0] ALERT_HANDLER_CLASSC_TIMEOUT_CYC_OFFSET = 8'h a0;
	parameter [7:0] ALERT_HANDLER_CLASSC_PHASE0_CYC_OFFSET = 8'h a4;
	parameter [7:0] ALERT_HANDLER_CLASSC_PHASE1_CYC_OFFSET = 8'h a8;
	parameter [7:0] ALERT_HANDLER_CLASSC_PHASE2_CYC_OFFSET = 8'h ac;
	parameter [7:0] ALERT_HANDLER_CLASSC_PHASE3_CYC_OFFSET = 8'h b0;
	parameter [7:0] ALERT_HANDLER_CLASSC_ESC_CNT_OFFSET = 8'h b4;
	parameter [7:0] ALERT_HANDLER_CLASSC_STATE_OFFSET = 8'h b8;
	parameter [7:0] ALERT_HANDLER_CLASSD_CTRL_OFFSET = 8'h bc;
	parameter [7:0] ALERT_HANDLER_CLASSD_CLREN_OFFSET = 8'h c0;
	parameter [7:0] ALERT_HANDLER_CLASSD_CLR_OFFSET = 8'h c4;
	parameter [7:0] ALERT_HANDLER_CLASSD_ACCUM_CNT_OFFSET = 8'h c8;
	parameter [7:0] ALERT_HANDLER_CLASSD_ACCUM_THRESH_OFFSET = 8'h cc;
	parameter [7:0] ALERT_HANDLER_CLASSD_TIMEOUT_CYC_OFFSET = 8'h d0;
	parameter [7:0] ALERT_HANDLER_CLASSD_PHASE0_CYC_OFFSET = 8'h d4;
	parameter [7:0] ALERT_HANDLER_CLASSD_PHASE1_CYC_OFFSET = 8'h d8;
	parameter [7:0] ALERT_HANDLER_CLASSD_PHASE2_CYC_OFFSET = 8'h dc;
	parameter [7:0] ALERT_HANDLER_CLASSD_PHASE3_CYC_OFFSET = 8'h e0;
	parameter [7:0] ALERT_HANDLER_CLASSD_ESC_CNT_OFFSET = 8'h e4;
	parameter [7:0] ALERT_HANDLER_CLASSD_STATE_OFFSET = 8'h e8;
	parameter [235:0] ALERT_HANDLER_PERMIT = {4'b 0001, 4'b 0001, 4'b 0001, 4'b 0001, 4'b 0111, 4'b 0001, 4'b 0001, 4'b 0001, 4'b 0001, 4'b 0001, 4'b 0001, 4'b 0011, 4'b 0001, 4'b 0001, 4'b 0011, 4'b 0011, 4'b 1111, 4'b 1111, 4'b 1111, 4'b 1111, 4'b 1111, 4'b 1111, 4'b 0001, 4'b 0011, 4'b 0001, 4'b 0001, 4'b 0011, 4'b 0011, 4'b 1111, 4'b 1111, 4'b 1111, 4'b 1111, 4'b 1111, 4'b 1111, 4'b 0001, 4'b 0011, 4'b 0001, 4'b 0001, 4'b 0011, 4'b 0011, 4'b 1111, 4'b 1111, 4'b 1111, 4'b 1111, 4'b 1111, 4'b 1111, 4'b 0001, 4'b 0011, 4'b 0001, 4'b 0001, 4'b 0011, 4'b 0011, 4'b 1111, 4'b 1111, 4'b 1111, 4'b 1111, 4'b 1111, 4'b 1111, 4'b 0001};
	localparam ALERT_HANDLER_INTR_STATE = 0;
	localparam ALERT_HANDLER_INTR_ENABLE = 1;
	localparam ALERT_HANDLER_LOC_ALERT_CAUSE = 10;
	localparam ALERT_HANDLER_CLASSA_CTRL = 11;
	localparam ALERT_HANDLER_CLASSA_CLREN = 12;
	localparam ALERT_HANDLER_CLASSA_CLR = 13;
	localparam ALERT_HANDLER_CLASSA_ACCUM_CNT = 14;
	localparam ALERT_HANDLER_CLASSA_ACCUM_THRESH = 15;
	localparam ALERT_HANDLER_CLASSA_TIMEOUT_CYC = 16;
	localparam ALERT_HANDLER_CLASSA_PHASE0_CYC = 17;
	localparam ALERT_HANDLER_CLASSA_PHASE1_CYC = 18;
	localparam ALERT_HANDLER_CLASSA_PHASE2_CYC = 19;
	localparam ALERT_HANDLER_INTR_TEST = 2;
	localparam ALERT_HANDLER_CLASSA_PHASE3_CYC = 20;
	localparam ALERT_HANDLER_CLASSA_ESC_CNT = 21;
	localparam ALERT_HANDLER_CLASSA_STATE = 22;
	localparam ALERT_HANDLER_CLASSB_CTRL = 23;
	localparam ALERT_HANDLER_CLASSB_CLREN = 24;
	localparam ALERT_HANDLER_CLASSB_CLR = 25;
	localparam ALERT_HANDLER_CLASSB_ACCUM_CNT = 26;
	localparam ALERT_HANDLER_CLASSB_ACCUM_THRESH = 27;
	localparam ALERT_HANDLER_CLASSB_TIMEOUT_CYC = 28;
	localparam ALERT_HANDLER_CLASSB_PHASE0_CYC = 29;
	localparam ALERT_HANDLER_REGEN = 3;
	localparam ALERT_HANDLER_CLASSB_PHASE1_CYC = 30;
	localparam ALERT_HANDLER_CLASSB_PHASE2_CYC = 31;
	localparam ALERT_HANDLER_CLASSB_PHASE3_CYC = 32;
	localparam ALERT_HANDLER_CLASSB_ESC_CNT = 33;
	localparam ALERT_HANDLER_CLASSB_STATE = 34;
	localparam ALERT_HANDLER_CLASSC_CTRL = 35;
	localparam ALERT_HANDLER_CLASSC_CLREN = 36;
	localparam ALERT_HANDLER_CLASSC_CLR = 37;
	localparam ALERT_HANDLER_CLASSC_ACCUM_CNT = 38;
	localparam ALERT_HANDLER_CLASSC_ACCUM_THRESH = 39;
	localparam ALERT_HANDLER_PING_TIMEOUT_CYC = 4;
	localparam ALERT_HANDLER_CLASSC_TIMEOUT_CYC = 40;
	localparam ALERT_HANDLER_CLASSC_PHASE0_CYC = 41;
	localparam ALERT_HANDLER_CLASSC_PHASE1_CYC = 42;
	localparam ALERT_HANDLER_CLASSC_PHASE2_CYC = 43;
	localparam ALERT_HANDLER_CLASSC_PHASE3_CYC = 44;
	localparam ALERT_HANDLER_CLASSC_ESC_CNT = 45;
	localparam ALERT_HANDLER_CLASSC_STATE = 46;
	localparam ALERT_HANDLER_CLASSD_CTRL = 47;
	localparam ALERT_HANDLER_CLASSD_CLREN = 48;
	localparam ALERT_HANDLER_CLASSD_CLR = 49;
	localparam ALERT_HANDLER_ALERT_EN = 5;
	localparam ALERT_HANDLER_CLASSD_ACCUM_CNT = 50;
	localparam ALERT_HANDLER_CLASSD_ACCUM_THRESH = 51;
	localparam ALERT_HANDLER_CLASSD_TIMEOUT_CYC = 52;
	localparam ALERT_HANDLER_CLASSD_PHASE0_CYC = 53;
	localparam ALERT_HANDLER_CLASSD_PHASE1_CYC = 54;
	localparam ALERT_HANDLER_CLASSD_PHASE2_CYC = 55;
	localparam ALERT_HANDLER_CLASSD_PHASE3_CYC = 56;
	localparam ALERT_HANDLER_CLASSD_ESC_CNT = 57;
	localparam ALERT_HANDLER_CLASSD_STATE = 58;
	localparam ALERT_HANDLER_ALERT_CLASS = 6;
	localparam ALERT_HANDLER_ALERT_CAUSE = 7;
	localparam ALERT_HANDLER_LOC_ALERT_EN = 8;
	localparam ALERT_HANDLER_LOC_ALERT_CLASS = 9;
	localparam signed [31:0] AW = 8;
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
	wire intr_state_classa_qs;
	wire intr_state_classa_wd;
	wire intr_state_classa_we;
	wire intr_state_classb_qs;
	wire intr_state_classb_wd;
	wire intr_state_classb_we;
	wire intr_state_classc_qs;
	wire intr_state_classc_wd;
	wire intr_state_classc_we;
	wire intr_state_classd_qs;
	wire intr_state_classd_wd;
	wire intr_state_classd_we;
	wire intr_enable_classa_qs;
	wire intr_enable_classa_wd;
	wire intr_enable_classa_we;
	wire intr_enable_classb_qs;
	wire intr_enable_classb_wd;
	wire intr_enable_classb_we;
	wire intr_enable_classc_qs;
	wire intr_enable_classc_wd;
	wire intr_enable_classc_we;
	wire intr_enable_classd_qs;
	wire intr_enable_classd_wd;
	wire intr_enable_classd_we;
	wire intr_test_classa_wd;
	wire intr_test_classa_we;
	wire intr_test_classb_wd;
	wire intr_test_classb_we;
	wire intr_test_classc_wd;
	wire intr_test_classc_we;
	wire intr_test_classd_wd;
	wire intr_test_classd_we;
	wire regen_qs;
	wire regen_wd;
	wire regen_we;
	wire [23:0] ping_timeout_cyc_qs;
	wire [23:0] ping_timeout_cyc_wd;
	wire ping_timeout_cyc_we;
	wire alert_en_qs;
	wire alert_en_wd;
	wire alert_en_we;
	wire [1:0] alert_class_qs;
	wire [1:0] alert_class_wd;
	wire alert_class_we;
	wire alert_cause_qs;
	wire alert_cause_wd;
	wire alert_cause_we;
	wire loc_alert_en_en_la0_qs;
	wire loc_alert_en_en_la0_wd;
	wire loc_alert_en_en_la0_we;
	wire loc_alert_en_en_la1_qs;
	wire loc_alert_en_en_la1_wd;
	wire loc_alert_en_en_la1_we;
	wire loc_alert_en_en_la2_qs;
	wire loc_alert_en_en_la2_wd;
	wire loc_alert_en_en_la2_we;
	wire loc_alert_en_en_la3_qs;
	wire loc_alert_en_en_la3_wd;
	wire loc_alert_en_en_la3_we;
	wire [1:0] loc_alert_class_class_la0_qs;
	wire [1:0] loc_alert_class_class_la0_wd;
	wire loc_alert_class_class_la0_we;
	wire [1:0] loc_alert_class_class_la1_qs;
	wire [1:0] loc_alert_class_class_la1_wd;
	wire loc_alert_class_class_la1_we;
	wire [1:0] loc_alert_class_class_la2_qs;
	wire [1:0] loc_alert_class_class_la2_wd;
	wire loc_alert_class_class_la2_we;
	wire [1:0] loc_alert_class_class_la3_qs;
	wire [1:0] loc_alert_class_class_la3_wd;
	wire loc_alert_class_class_la3_we;
	wire loc_alert_cause_la0_qs;
	wire loc_alert_cause_la0_wd;
	wire loc_alert_cause_la0_we;
	wire loc_alert_cause_la1_qs;
	wire loc_alert_cause_la1_wd;
	wire loc_alert_cause_la1_we;
	wire loc_alert_cause_la2_qs;
	wire loc_alert_cause_la2_wd;
	wire loc_alert_cause_la2_we;
	wire loc_alert_cause_la3_qs;
	wire loc_alert_cause_la3_wd;
	wire loc_alert_cause_la3_we;
	wire classa_ctrl_en_qs;
	wire classa_ctrl_en_wd;
	wire classa_ctrl_en_we;
	wire classa_ctrl_lock_qs;
	wire classa_ctrl_lock_wd;
	wire classa_ctrl_lock_we;
	wire classa_ctrl_en_e0_qs;
	wire classa_ctrl_en_e0_wd;
	wire classa_ctrl_en_e0_we;
	wire classa_ctrl_en_e1_qs;
	wire classa_ctrl_en_e1_wd;
	wire classa_ctrl_en_e1_we;
	wire classa_ctrl_en_e2_qs;
	wire classa_ctrl_en_e2_wd;
	wire classa_ctrl_en_e2_we;
	wire classa_ctrl_en_e3_qs;
	wire classa_ctrl_en_e3_wd;
	wire classa_ctrl_en_e3_we;
	wire [1:0] classa_ctrl_map_e0_qs;
	wire [1:0] classa_ctrl_map_e0_wd;
	wire classa_ctrl_map_e0_we;
	wire [1:0] classa_ctrl_map_e1_qs;
	wire [1:0] classa_ctrl_map_e1_wd;
	wire classa_ctrl_map_e1_we;
	wire [1:0] classa_ctrl_map_e2_qs;
	wire [1:0] classa_ctrl_map_e2_wd;
	wire classa_ctrl_map_e2_we;
	wire [1:0] classa_ctrl_map_e3_qs;
	wire [1:0] classa_ctrl_map_e3_wd;
	wire classa_ctrl_map_e3_we;
	wire classa_clren_qs;
	wire classa_clren_wd;
	wire classa_clren_we;
	wire classa_clr_wd;
	wire classa_clr_we;
	wire [15:0] classa_accum_cnt_qs;
	wire classa_accum_cnt_re;
	wire [15:0] classa_accum_thresh_qs;
	wire [15:0] classa_accum_thresh_wd;
	wire classa_accum_thresh_we;
	wire [31:0] classa_timeout_cyc_qs;
	wire [31:0] classa_timeout_cyc_wd;
	wire classa_timeout_cyc_we;
	wire [31:0] classa_phase0_cyc_qs;
	wire [31:0] classa_phase0_cyc_wd;
	wire classa_phase0_cyc_we;
	wire [31:0] classa_phase1_cyc_qs;
	wire [31:0] classa_phase1_cyc_wd;
	wire classa_phase1_cyc_we;
	wire [31:0] classa_phase2_cyc_qs;
	wire [31:0] classa_phase2_cyc_wd;
	wire classa_phase2_cyc_we;
	wire [31:0] classa_phase3_cyc_qs;
	wire [31:0] classa_phase3_cyc_wd;
	wire classa_phase3_cyc_we;
	wire [31:0] classa_esc_cnt_qs;
	wire classa_esc_cnt_re;
	wire [2:0] classa_state_qs;
	wire classa_state_re;
	wire classb_ctrl_en_qs;
	wire classb_ctrl_en_wd;
	wire classb_ctrl_en_we;
	wire classb_ctrl_lock_qs;
	wire classb_ctrl_lock_wd;
	wire classb_ctrl_lock_we;
	wire classb_ctrl_en_e0_qs;
	wire classb_ctrl_en_e0_wd;
	wire classb_ctrl_en_e0_we;
	wire classb_ctrl_en_e1_qs;
	wire classb_ctrl_en_e1_wd;
	wire classb_ctrl_en_e1_we;
	wire classb_ctrl_en_e2_qs;
	wire classb_ctrl_en_e2_wd;
	wire classb_ctrl_en_e2_we;
	wire classb_ctrl_en_e3_qs;
	wire classb_ctrl_en_e3_wd;
	wire classb_ctrl_en_e3_we;
	wire [1:0] classb_ctrl_map_e0_qs;
	wire [1:0] classb_ctrl_map_e0_wd;
	wire classb_ctrl_map_e0_we;
	wire [1:0] classb_ctrl_map_e1_qs;
	wire [1:0] classb_ctrl_map_e1_wd;
	wire classb_ctrl_map_e1_we;
	wire [1:0] classb_ctrl_map_e2_qs;
	wire [1:0] classb_ctrl_map_e2_wd;
	wire classb_ctrl_map_e2_we;
	wire [1:0] classb_ctrl_map_e3_qs;
	wire [1:0] classb_ctrl_map_e3_wd;
	wire classb_ctrl_map_e3_we;
	wire classb_clren_qs;
	wire classb_clren_wd;
	wire classb_clren_we;
	wire classb_clr_wd;
	wire classb_clr_we;
	wire [15:0] classb_accum_cnt_qs;
	wire classb_accum_cnt_re;
	wire [15:0] classb_accum_thresh_qs;
	wire [15:0] classb_accum_thresh_wd;
	wire classb_accum_thresh_we;
	wire [31:0] classb_timeout_cyc_qs;
	wire [31:0] classb_timeout_cyc_wd;
	wire classb_timeout_cyc_we;
	wire [31:0] classb_phase0_cyc_qs;
	wire [31:0] classb_phase0_cyc_wd;
	wire classb_phase0_cyc_we;
	wire [31:0] classb_phase1_cyc_qs;
	wire [31:0] classb_phase1_cyc_wd;
	wire classb_phase1_cyc_we;
	wire [31:0] classb_phase2_cyc_qs;
	wire [31:0] classb_phase2_cyc_wd;
	wire classb_phase2_cyc_we;
	wire [31:0] classb_phase3_cyc_qs;
	wire [31:0] classb_phase3_cyc_wd;
	wire classb_phase3_cyc_we;
	wire [31:0] classb_esc_cnt_qs;
	wire classb_esc_cnt_re;
	wire [2:0] classb_state_qs;
	wire classb_state_re;
	wire classc_ctrl_en_qs;
	wire classc_ctrl_en_wd;
	wire classc_ctrl_en_we;
	wire classc_ctrl_lock_qs;
	wire classc_ctrl_lock_wd;
	wire classc_ctrl_lock_we;
	wire classc_ctrl_en_e0_qs;
	wire classc_ctrl_en_e0_wd;
	wire classc_ctrl_en_e0_we;
	wire classc_ctrl_en_e1_qs;
	wire classc_ctrl_en_e1_wd;
	wire classc_ctrl_en_e1_we;
	wire classc_ctrl_en_e2_qs;
	wire classc_ctrl_en_e2_wd;
	wire classc_ctrl_en_e2_we;
	wire classc_ctrl_en_e3_qs;
	wire classc_ctrl_en_e3_wd;
	wire classc_ctrl_en_e3_we;
	wire [1:0] classc_ctrl_map_e0_qs;
	wire [1:0] classc_ctrl_map_e0_wd;
	wire classc_ctrl_map_e0_we;
	wire [1:0] classc_ctrl_map_e1_qs;
	wire [1:0] classc_ctrl_map_e1_wd;
	wire classc_ctrl_map_e1_we;
	wire [1:0] classc_ctrl_map_e2_qs;
	wire [1:0] classc_ctrl_map_e2_wd;
	wire classc_ctrl_map_e2_we;
	wire [1:0] classc_ctrl_map_e3_qs;
	wire [1:0] classc_ctrl_map_e3_wd;
	wire classc_ctrl_map_e3_we;
	wire classc_clren_qs;
	wire classc_clren_wd;
	wire classc_clren_we;
	wire classc_clr_wd;
	wire classc_clr_we;
	wire [15:0] classc_accum_cnt_qs;
	wire classc_accum_cnt_re;
	wire [15:0] classc_accum_thresh_qs;
	wire [15:0] classc_accum_thresh_wd;
	wire classc_accum_thresh_we;
	wire [31:0] classc_timeout_cyc_qs;
	wire [31:0] classc_timeout_cyc_wd;
	wire classc_timeout_cyc_we;
	wire [31:0] classc_phase0_cyc_qs;
	wire [31:0] classc_phase0_cyc_wd;
	wire classc_phase0_cyc_we;
	wire [31:0] classc_phase1_cyc_qs;
	wire [31:0] classc_phase1_cyc_wd;
	wire classc_phase1_cyc_we;
	wire [31:0] classc_phase2_cyc_qs;
	wire [31:0] classc_phase2_cyc_wd;
	wire classc_phase2_cyc_we;
	wire [31:0] classc_phase3_cyc_qs;
	wire [31:0] classc_phase3_cyc_wd;
	wire classc_phase3_cyc_we;
	wire [31:0] classc_esc_cnt_qs;
	wire classc_esc_cnt_re;
	wire [2:0] classc_state_qs;
	wire classc_state_re;
	wire classd_ctrl_en_qs;
	wire classd_ctrl_en_wd;
	wire classd_ctrl_en_we;
	wire classd_ctrl_lock_qs;
	wire classd_ctrl_lock_wd;
	wire classd_ctrl_lock_we;
	wire classd_ctrl_en_e0_qs;
	wire classd_ctrl_en_e0_wd;
	wire classd_ctrl_en_e0_we;
	wire classd_ctrl_en_e1_qs;
	wire classd_ctrl_en_e1_wd;
	wire classd_ctrl_en_e1_we;
	wire classd_ctrl_en_e2_qs;
	wire classd_ctrl_en_e2_wd;
	wire classd_ctrl_en_e2_we;
	wire classd_ctrl_en_e3_qs;
	wire classd_ctrl_en_e3_wd;
	wire classd_ctrl_en_e3_we;
	wire [1:0] classd_ctrl_map_e0_qs;
	wire [1:0] classd_ctrl_map_e0_wd;
	wire classd_ctrl_map_e0_we;
	wire [1:0] classd_ctrl_map_e1_qs;
	wire [1:0] classd_ctrl_map_e1_wd;
	wire classd_ctrl_map_e1_we;
	wire [1:0] classd_ctrl_map_e2_qs;
	wire [1:0] classd_ctrl_map_e2_wd;
	wire classd_ctrl_map_e2_we;
	wire [1:0] classd_ctrl_map_e3_qs;
	wire [1:0] classd_ctrl_map_e3_wd;
	wire classd_ctrl_map_e3_we;
	wire classd_clren_qs;
	wire classd_clren_wd;
	wire classd_clren_we;
	wire classd_clr_wd;
	wire classd_clr_we;
	wire [15:0] classd_accum_cnt_qs;
	wire classd_accum_cnt_re;
	wire [15:0] classd_accum_thresh_qs;
	wire [15:0] classd_accum_thresh_wd;
	wire classd_accum_thresh_we;
	wire [31:0] classd_timeout_cyc_qs;
	wire [31:0] classd_timeout_cyc_wd;
	wire classd_timeout_cyc_we;
	wire [31:0] classd_phase0_cyc_qs;
	wire [31:0] classd_phase0_cyc_wd;
	wire classd_phase0_cyc_we;
	wire [31:0] classd_phase1_cyc_qs;
	wire [31:0] classd_phase1_cyc_wd;
	wire classd_phase1_cyc_we;
	wire [31:0] classd_phase2_cyc_qs;
	wire [31:0] classd_phase2_cyc_wd;
	wire classd_phase2_cyc_we;
	wire [31:0] classd_phase3_cyc_qs;
	wire [31:0] classd_phase3_cyc_wd;
	wire classd_phase3_cyc_we;
	wire [31:0] classd_esc_cnt_qs;
	wire classd_esc_cnt_re;
	wire [2:0] classd_state_qs;
	wire classd_state_re;
	prim_subreg #(
		.DW(1),
		.SWACCESS("W1C"),
		.RESVAL(1'h0)
	) u_intr_state_classa(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(intr_state_classa_we),
		.wd(intr_state_classa_wd),
		.de(hw2reg[228]),
		.d(hw2reg[229]),
		.qe(),
		.q(reg2hw[828]),
		.qs(intr_state_classa_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("W1C"),
		.RESVAL(1'h0)
	) u_intr_state_classb(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(intr_state_classb_we),
		.wd(intr_state_classb_wd),
		.de(hw2reg[226]),
		.d(hw2reg[227]),
		.qe(),
		.q(reg2hw[827]),
		.qs(intr_state_classb_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("W1C"),
		.RESVAL(1'h0)
	) u_intr_state_classc(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(intr_state_classc_we),
		.wd(intr_state_classc_wd),
		.de(hw2reg[224]),
		.d(hw2reg[225]),
		.qe(),
		.q(reg2hw[826]),
		.qs(intr_state_classc_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("W1C"),
		.RESVAL(1'h0)
	) u_intr_state_classd(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(intr_state_classd_we),
		.wd(intr_state_classd_wd),
		.de(hw2reg[222]),
		.d(hw2reg[223]),
		.qe(),
		.q(reg2hw[825]),
		.qs(intr_state_classd_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_intr_enable_classa(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(intr_enable_classa_we),
		.wd(intr_enable_classa_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[824]),
		.qs(intr_enable_classa_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_intr_enable_classb(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(intr_enable_classb_we),
		.wd(intr_enable_classb_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[823]),
		.qs(intr_enable_classb_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_intr_enable_classc(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(intr_enable_classc_we),
		.wd(intr_enable_classc_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[822]),
		.qs(intr_enable_classc_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_intr_enable_classd(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(intr_enable_classd_we),
		.wd(intr_enable_classd_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[821]),
		.qs(intr_enable_classd_qs)
	);
	prim_subreg_ext #(.DW(1)) u_intr_test_classa(
		.re(1'b0),
		.we(intr_test_classa_we),
		.wd(intr_test_classa_wd),
		.d(1'sb0),
		.qre(),
		.qe(reg2hw[819]),
		.q(reg2hw[820]),
		.qs()
	);
	prim_subreg_ext #(.DW(1)) u_intr_test_classb(
		.re(1'b0),
		.we(intr_test_classb_we),
		.wd(intr_test_classb_wd),
		.d(1'sb0),
		.qre(),
		.qe(reg2hw[817]),
		.q(reg2hw[818]),
		.qs()
	);
	prim_subreg_ext #(.DW(1)) u_intr_test_classc(
		.re(1'b0),
		.we(intr_test_classc_we),
		.wd(intr_test_classc_wd),
		.d(1'sb0),
		.qre(),
		.qe(reg2hw[815]),
		.q(reg2hw[816]),
		.qs()
	);
	prim_subreg_ext #(.DW(1)) u_intr_test_classd(
		.re(1'b0),
		.we(intr_test_classd_we),
		.wd(intr_test_classd_wd),
		.d(1'sb0),
		.qre(),
		.qe(reg2hw[813]),
		.q(reg2hw[814]),
		.qs()
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("W1C"),
		.RESVAL(1'h1)
	) u_regen(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(regen_we),
		.wd(regen_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[812]),
		.qs(regen_qs)
	);
	prim_subreg #(
		.DW(24),
		.SWACCESS("RW"),
		.RESVAL(24'h20)
	) u_ping_timeout_cyc(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(ping_timeout_cyc_we & regen_qs),
		.wd(ping_timeout_cyc_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[811-:24]),
		.qs(ping_timeout_cyc_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_alert_en(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(alert_en_we & regen_qs),
		.wd(alert_en_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[787]),
		.qs(alert_en_qs)
	);
	prim_subreg #(
		.DW(2),
		.SWACCESS("RW"),
		.RESVAL(2'h0)
	) u_alert_class(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(alert_class_we & regen_qs),
		.wd(alert_class_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[786-:2]),
		.qs(alert_class_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("W1C"),
		.RESVAL(1'h0)
	) u_alert_cause(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(alert_cause_we),
		.wd(alert_cause_wd),
		.de(hw2reg[220]),
		.d(hw2reg[221]),
		.qe(),
		.q(reg2hw[784]),
		.qs(alert_cause_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_loc_alert_en_en_la0(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(loc_alert_en_en_la0_we & regen_qs),
		.wd(loc_alert_en_en_la0_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[780]),
		.qs(loc_alert_en_en_la0_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_loc_alert_en_en_la1(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(loc_alert_en_en_la1_we & regen_qs),
		.wd(loc_alert_en_en_la1_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[781]),
		.qs(loc_alert_en_en_la1_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_loc_alert_en_en_la2(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(loc_alert_en_en_la2_we & regen_qs),
		.wd(loc_alert_en_en_la2_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[782]),
		.qs(loc_alert_en_en_la2_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_loc_alert_en_en_la3(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(loc_alert_en_en_la3_we & regen_qs),
		.wd(loc_alert_en_en_la3_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[783]),
		.qs(loc_alert_en_en_la3_qs)
	);
	prim_subreg #(
		.DW(2),
		.SWACCESS("RW"),
		.RESVAL(2'h0)
	) u_loc_alert_class_class_la0(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(loc_alert_class_class_la0_we & regen_qs),
		.wd(loc_alert_class_class_la0_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[773-:2]),
		.qs(loc_alert_class_class_la0_qs)
	);
	prim_subreg #(
		.DW(2),
		.SWACCESS("RW"),
		.RESVAL(2'h0)
	) u_loc_alert_class_class_la1(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(loc_alert_class_class_la1_we & regen_qs),
		.wd(loc_alert_class_class_la1_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[775-:2]),
		.qs(loc_alert_class_class_la1_qs)
	);
	prim_subreg #(
		.DW(2),
		.SWACCESS("RW"),
		.RESVAL(2'h0)
	) u_loc_alert_class_class_la2(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(loc_alert_class_class_la2_we & regen_qs),
		.wd(loc_alert_class_class_la2_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[777-:2]),
		.qs(loc_alert_class_class_la2_qs)
	);
	prim_subreg #(
		.DW(2),
		.SWACCESS("RW"),
		.RESVAL(2'h0)
	) u_loc_alert_class_class_la3(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(loc_alert_class_class_la3_we & regen_qs),
		.wd(loc_alert_class_class_la3_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[779-:2]),
		.qs(loc_alert_class_class_la3_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("W1C"),
		.RESVAL(1'h0)
	) u_loc_alert_cause_la0(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(loc_alert_cause_la0_we),
		.wd(loc_alert_cause_la0_wd),
		.de(hw2reg[212]),
		.d(hw2reg[213]),
		.qe(),
		.q(reg2hw[768]),
		.qs(loc_alert_cause_la0_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("W1C"),
		.RESVAL(1'h0)
	) u_loc_alert_cause_la1(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(loc_alert_cause_la1_we),
		.wd(loc_alert_cause_la1_wd),
		.de(hw2reg[214]),
		.d(hw2reg[215]),
		.qe(),
		.q(reg2hw[769]),
		.qs(loc_alert_cause_la1_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("W1C"),
		.RESVAL(1'h0)
	) u_loc_alert_cause_la2(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(loc_alert_cause_la2_we),
		.wd(loc_alert_cause_la2_wd),
		.de(hw2reg[216]),
		.d(hw2reg[217]),
		.qe(),
		.q(reg2hw[770]),
		.qs(loc_alert_cause_la2_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("W1C"),
		.RESVAL(1'h0)
	) u_loc_alert_cause_la3(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(loc_alert_cause_la3_we),
		.wd(loc_alert_cause_la3_wd),
		.de(hw2reg[218]),
		.d(hw2reg[219]),
		.qe(),
		.q(reg2hw[771]),
		.qs(loc_alert_cause_la3_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_classa_ctrl_en(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(classa_ctrl_en_we & regen_qs),
		.wd(classa_ctrl_en_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[767]),
		.qs(classa_ctrl_en_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_classa_ctrl_lock(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(classa_ctrl_lock_we & regen_qs),
		.wd(classa_ctrl_lock_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[766]),
		.qs(classa_ctrl_lock_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h1)
	) u_classa_ctrl_en_e0(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(classa_ctrl_en_e0_we & regen_qs),
		.wd(classa_ctrl_en_e0_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[765]),
		.qs(classa_ctrl_en_e0_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h1)
	) u_classa_ctrl_en_e1(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(classa_ctrl_en_e1_we & regen_qs),
		.wd(classa_ctrl_en_e1_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[764]),
		.qs(classa_ctrl_en_e1_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h1)
	) u_classa_ctrl_en_e2(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(classa_ctrl_en_e2_we & regen_qs),
		.wd(classa_ctrl_en_e2_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[763]),
		.qs(classa_ctrl_en_e2_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h1)
	) u_classa_ctrl_en_e3(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(classa_ctrl_en_e3_we & regen_qs),
		.wd(classa_ctrl_en_e3_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[762]),
		.qs(classa_ctrl_en_e3_qs)
	);
	prim_subreg #(
		.DW(2),
		.SWACCESS("RW"),
		.RESVAL(2'h0)
	) u_classa_ctrl_map_e0(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(classa_ctrl_map_e0_we & regen_qs),
		.wd(classa_ctrl_map_e0_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[761-:2]),
		.qs(classa_ctrl_map_e0_qs)
	);
	prim_subreg #(
		.DW(2),
		.SWACCESS("RW"),
		.RESVAL(2'h1)
	) u_classa_ctrl_map_e1(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(classa_ctrl_map_e1_we & regen_qs),
		.wd(classa_ctrl_map_e1_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[759-:2]),
		.qs(classa_ctrl_map_e1_qs)
	);
	prim_subreg #(
		.DW(2),
		.SWACCESS("RW"),
		.RESVAL(2'h2)
	) u_classa_ctrl_map_e2(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(classa_ctrl_map_e2_we & regen_qs),
		.wd(classa_ctrl_map_e2_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[757-:2]),
		.qs(classa_ctrl_map_e2_qs)
	);
	prim_subreg #(
		.DW(2),
		.SWACCESS("RW"),
		.RESVAL(2'h3)
	) u_classa_ctrl_map_e3(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(classa_ctrl_map_e3_we & regen_qs),
		.wd(classa_ctrl_map_e3_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[755-:2]),
		.qs(classa_ctrl_map_e3_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("W1C"),
		.RESVAL(1'h1)
	) u_classa_clren(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(classa_clren_we),
		.wd(classa_clren_wd),
		.de(hw2reg[210]),
		.d(hw2reg[211]),
		.qe(),
		.q(),
		.qs(classa_clren_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("WO"),
		.RESVAL(1'h0)
	) u_classa_clr(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(classa_clr_we & classa_clren_qs),
		.wd(classa_clr_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(reg2hw[752]),
		.q(reg2hw[753]),
		.qs()
	);
	prim_subreg_ext #(.DW(16)) u_classa_accum_cnt(
		.re(classa_accum_cnt_re),
		.we(1'b0),
		.wd(1'sb0),
		.d(hw2reg[209-:16]),
		.qre(),
		.qe(),
		.q(),
		.qs(classa_accum_cnt_qs)
	);
	prim_subreg #(
		.DW(16),
		.SWACCESS("RW"),
		.RESVAL(16'h0)
	) u_classa_accum_thresh(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(classa_accum_thresh_we & regen_qs),
		.wd(classa_accum_thresh_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[751-:16]),
		.qs(classa_accum_thresh_qs)
	);
	prim_subreg #(
		.DW(32),
		.SWACCESS("RW"),
		.RESVAL(32'h0)
	) u_classa_timeout_cyc(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(classa_timeout_cyc_we & regen_qs),
		.wd(classa_timeout_cyc_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[735-:32]),
		.qs(classa_timeout_cyc_qs)
	);
	prim_subreg #(
		.DW(32),
		.SWACCESS("RW"),
		.RESVAL(32'h0)
	) u_classa_phase0_cyc(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(classa_phase0_cyc_we & regen_qs),
		.wd(classa_phase0_cyc_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[703-:32]),
		.qs(classa_phase0_cyc_qs)
	);
	prim_subreg #(
		.DW(32),
		.SWACCESS("RW"),
		.RESVAL(32'h0)
	) u_classa_phase1_cyc(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(classa_phase1_cyc_we & regen_qs),
		.wd(classa_phase1_cyc_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[671-:32]),
		.qs(classa_phase1_cyc_qs)
	);
	prim_subreg #(
		.DW(32),
		.SWACCESS("RW"),
		.RESVAL(32'h0)
	) u_classa_phase2_cyc(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(classa_phase2_cyc_we & regen_qs),
		.wd(classa_phase2_cyc_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[639-:32]),
		.qs(classa_phase2_cyc_qs)
	);
	prim_subreg #(
		.DW(32),
		.SWACCESS("RW"),
		.RESVAL(32'h0)
	) u_classa_phase3_cyc(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(classa_phase3_cyc_we & regen_qs),
		.wd(classa_phase3_cyc_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[607-:32]),
		.qs(classa_phase3_cyc_qs)
	);
	prim_subreg_ext #(.DW(32)) u_classa_esc_cnt(
		.re(classa_esc_cnt_re),
		.we(1'b0),
		.wd(1'sb0),
		.d(hw2reg[193-:32]),
		.qre(),
		.qe(),
		.q(),
		.qs(classa_esc_cnt_qs)
	);
	prim_subreg_ext #(.DW(3)) u_classa_state(
		.re(classa_state_re),
		.we(1'b0),
		.wd(1'sb0),
		.d(hw2reg[161-:3]),
		.qre(),
		.qe(),
		.q(),
		.qs(classa_state_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_classb_ctrl_en(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(classb_ctrl_en_we & regen_qs),
		.wd(classb_ctrl_en_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[575]),
		.qs(classb_ctrl_en_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_classb_ctrl_lock(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(classb_ctrl_lock_we & regen_qs),
		.wd(classb_ctrl_lock_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[574]),
		.qs(classb_ctrl_lock_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h1)
	) u_classb_ctrl_en_e0(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(classb_ctrl_en_e0_we & regen_qs),
		.wd(classb_ctrl_en_e0_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[573]),
		.qs(classb_ctrl_en_e0_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h1)
	) u_classb_ctrl_en_e1(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(classb_ctrl_en_e1_we & regen_qs),
		.wd(classb_ctrl_en_e1_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[572]),
		.qs(classb_ctrl_en_e1_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h1)
	) u_classb_ctrl_en_e2(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(classb_ctrl_en_e2_we & regen_qs),
		.wd(classb_ctrl_en_e2_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[571]),
		.qs(classb_ctrl_en_e2_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h1)
	) u_classb_ctrl_en_e3(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(classb_ctrl_en_e3_we & regen_qs),
		.wd(classb_ctrl_en_e3_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[570]),
		.qs(classb_ctrl_en_e3_qs)
	);
	prim_subreg #(
		.DW(2),
		.SWACCESS("RW"),
		.RESVAL(2'h0)
	) u_classb_ctrl_map_e0(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(classb_ctrl_map_e0_we & regen_qs),
		.wd(classb_ctrl_map_e0_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[569-:2]),
		.qs(classb_ctrl_map_e0_qs)
	);
	prim_subreg #(
		.DW(2),
		.SWACCESS("RW"),
		.RESVAL(2'h1)
	) u_classb_ctrl_map_e1(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(classb_ctrl_map_e1_we & regen_qs),
		.wd(classb_ctrl_map_e1_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[567-:2]),
		.qs(classb_ctrl_map_e1_qs)
	);
	prim_subreg #(
		.DW(2),
		.SWACCESS("RW"),
		.RESVAL(2'h2)
	) u_classb_ctrl_map_e2(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(classb_ctrl_map_e2_we & regen_qs),
		.wd(classb_ctrl_map_e2_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[565-:2]),
		.qs(classb_ctrl_map_e2_qs)
	);
	prim_subreg #(
		.DW(2),
		.SWACCESS("RW"),
		.RESVAL(2'h3)
	) u_classb_ctrl_map_e3(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(classb_ctrl_map_e3_we & regen_qs),
		.wd(classb_ctrl_map_e3_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[563-:2]),
		.qs(classb_ctrl_map_e3_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("W1C"),
		.RESVAL(1'h1)
	) u_classb_clren(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(classb_clren_we),
		.wd(classb_clren_wd),
		.de(hw2reg[157]),
		.d(hw2reg[158]),
		.qe(),
		.q(),
		.qs(classb_clren_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("WO"),
		.RESVAL(1'h0)
	) u_classb_clr(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(classb_clr_we & classb_clren_qs),
		.wd(classb_clr_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(reg2hw[560]),
		.q(reg2hw[561]),
		.qs()
	);
	prim_subreg_ext #(.DW(16)) u_classb_accum_cnt(
		.re(classb_accum_cnt_re),
		.we(1'b0),
		.wd(1'sb0),
		.d(hw2reg[156-:16]),
		.qre(),
		.qe(),
		.q(),
		.qs(classb_accum_cnt_qs)
	);
	prim_subreg #(
		.DW(16),
		.SWACCESS("RW"),
		.RESVAL(16'h0)
	) u_classb_accum_thresh(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(classb_accum_thresh_we & regen_qs),
		.wd(classb_accum_thresh_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[559-:16]),
		.qs(classb_accum_thresh_qs)
	);
	prim_subreg #(
		.DW(32),
		.SWACCESS("RW"),
		.RESVAL(32'h0)
	) u_classb_timeout_cyc(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(classb_timeout_cyc_we & regen_qs),
		.wd(classb_timeout_cyc_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[543-:32]),
		.qs(classb_timeout_cyc_qs)
	);
	prim_subreg #(
		.DW(32),
		.SWACCESS("RW"),
		.RESVAL(32'h0)
	) u_classb_phase0_cyc(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(classb_phase0_cyc_we & regen_qs),
		.wd(classb_phase0_cyc_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[511-:32]),
		.qs(classb_phase0_cyc_qs)
	);
	prim_subreg #(
		.DW(32),
		.SWACCESS("RW"),
		.RESVAL(32'h0)
	) u_classb_phase1_cyc(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(classb_phase1_cyc_we & regen_qs),
		.wd(classb_phase1_cyc_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[479-:32]),
		.qs(classb_phase1_cyc_qs)
	);
	prim_subreg #(
		.DW(32),
		.SWACCESS("RW"),
		.RESVAL(32'h0)
	) u_classb_phase2_cyc(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(classb_phase2_cyc_we & regen_qs),
		.wd(classb_phase2_cyc_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[447-:32]),
		.qs(classb_phase2_cyc_qs)
	);
	prim_subreg #(
		.DW(32),
		.SWACCESS("RW"),
		.RESVAL(32'h0)
	) u_classb_phase3_cyc(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(classb_phase3_cyc_we & regen_qs),
		.wd(classb_phase3_cyc_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[415-:32]),
		.qs(classb_phase3_cyc_qs)
	);
	prim_subreg_ext #(.DW(32)) u_classb_esc_cnt(
		.re(classb_esc_cnt_re),
		.we(1'b0),
		.wd(1'sb0),
		.d(hw2reg[140-:32]),
		.qre(),
		.qe(),
		.q(),
		.qs(classb_esc_cnt_qs)
	);
	prim_subreg_ext #(.DW(3)) u_classb_state(
		.re(classb_state_re),
		.we(1'b0),
		.wd(1'sb0),
		.d(hw2reg[108-:3]),
		.qre(),
		.qe(),
		.q(),
		.qs(classb_state_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_classc_ctrl_en(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(classc_ctrl_en_we & regen_qs),
		.wd(classc_ctrl_en_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[383]),
		.qs(classc_ctrl_en_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_classc_ctrl_lock(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(classc_ctrl_lock_we & regen_qs),
		.wd(classc_ctrl_lock_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[382]),
		.qs(classc_ctrl_lock_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h1)
	) u_classc_ctrl_en_e0(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(classc_ctrl_en_e0_we & regen_qs),
		.wd(classc_ctrl_en_e0_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[381]),
		.qs(classc_ctrl_en_e0_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h1)
	) u_classc_ctrl_en_e1(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(classc_ctrl_en_e1_we & regen_qs),
		.wd(classc_ctrl_en_e1_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[380]),
		.qs(classc_ctrl_en_e1_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h1)
	) u_classc_ctrl_en_e2(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(classc_ctrl_en_e2_we & regen_qs),
		.wd(classc_ctrl_en_e2_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[379]),
		.qs(classc_ctrl_en_e2_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h1)
	) u_classc_ctrl_en_e3(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(classc_ctrl_en_e3_we & regen_qs),
		.wd(classc_ctrl_en_e3_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[378]),
		.qs(classc_ctrl_en_e3_qs)
	);
	prim_subreg #(
		.DW(2),
		.SWACCESS("RW"),
		.RESVAL(2'h0)
	) u_classc_ctrl_map_e0(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(classc_ctrl_map_e0_we & regen_qs),
		.wd(classc_ctrl_map_e0_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[377-:2]),
		.qs(classc_ctrl_map_e0_qs)
	);
	prim_subreg #(
		.DW(2),
		.SWACCESS("RW"),
		.RESVAL(2'h1)
	) u_classc_ctrl_map_e1(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(classc_ctrl_map_e1_we & regen_qs),
		.wd(classc_ctrl_map_e1_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[375-:2]),
		.qs(classc_ctrl_map_e1_qs)
	);
	prim_subreg #(
		.DW(2),
		.SWACCESS("RW"),
		.RESVAL(2'h2)
	) u_classc_ctrl_map_e2(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(classc_ctrl_map_e2_we & regen_qs),
		.wd(classc_ctrl_map_e2_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[373-:2]),
		.qs(classc_ctrl_map_e2_qs)
	);
	prim_subreg #(
		.DW(2),
		.SWACCESS("RW"),
		.RESVAL(2'h3)
	) u_classc_ctrl_map_e3(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(classc_ctrl_map_e3_we & regen_qs),
		.wd(classc_ctrl_map_e3_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[371-:2]),
		.qs(classc_ctrl_map_e3_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("W1C"),
		.RESVAL(1'h1)
	) u_classc_clren(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(classc_clren_we),
		.wd(classc_clren_wd),
		.de(hw2reg[104]),
		.d(hw2reg[105]),
		.qe(),
		.q(),
		.qs(classc_clren_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("WO"),
		.RESVAL(1'h0)
	) u_classc_clr(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(classc_clr_we & classc_clren_qs),
		.wd(classc_clr_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(reg2hw[368]),
		.q(reg2hw[369]),
		.qs()
	);
	prim_subreg_ext #(.DW(16)) u_classc_accum_cnt(
		.re(classc_accum_cnt_re),
		.we(1'b0),
		.wd(1'sb0),
		.d(hw2reg[103-:16]),
		.qre(),
		.qe(),
		.q(),
		.qs(classc_accum_cnt_qs)
	);
	prim_subreg #(
		.DW(16),
		.SWACCESS("RW"),
		.RESVAL(16'h0)
	) u_classc_accum_thresh(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(classc_accum_thresh_we & regen_qs),
		.wd(classc_accum_thresh_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[367-:16]),
		.qs(classc_accum_thresh_qs)
	);
	prim_subreg #(
		.DW(32),
		.SWACCESS("RW"),
		.RESVAL(32'h0)
	) u_classc_timeout_cyc(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(classc_timeout_cyc_we & regen_qs),
		.wd(classc_timeout_cyc_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[351-:32]),
		.qs(classc_timeout_cyc_qs)
	);
	prim_subreg #(
		.DW(32),
		.SWACCESS("RW"),
		.RESVAL(32'h0)
	) u_classc_phase0_cyc(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(classc_phase0_cyc_we & regen_qs),
		.wd(classc_phase0_cyc_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[319-:32]),
		.qs(classc_phase0_cyc_qs)
	);
	prim_subreg #(
		.DW(32),
		.SWACCESS("RW"),
		.RESVAL(32'h0)
	) u_classc_phase1_cyc(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(classc_phase1_cyc_we & regen_qs),
		.wd(classc_phase1_cyc_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[287-:32]),
		.qs(classc_phase1_cyc_qs)
	);
	prim_subreg #(
		.DW(32),
		.SWACCESS("RW"),
		.RESVAL(32'h0)
	) u_classc_phase2_cyc(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(classc_phase2_cyc_we & regen_qs),
		.wd(classc_phase2_cyc_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[255-:32]),
		.qs(classc_phase2_cyc_qs)
	);
	prim_subreg #(
		.DW(32),
		.SWACCESS("RW"),
		.RESVAL(32'h0)
	) u_classc_phase3_cyc(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(classc_phase3_cyc_we & regen_qs),
		.wd(classc_phase3_cyc_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[223-:32]),
		.qs(classc_phase3_cyc_qs)
	);
	prim_subreg_ext #(.DW(32)) u_classc_esc_cnt(
		.re(classc_esc_cnt_re),
		.we(1'b0),
		.wd(1'sb0),
		.d(hw2reg[87-:32]),
		.qre(),
		.qe(),
		.q(),
		.qs(classc_esc_cnt_qs)
	);
	prim_subreg_ext #(.DW(3)) u_classc_state(
		.re(classc_state_re),
		.we(1'b0),
		.wd(1'sb0),
		.d(hw2reg[55-:3]),
		.qre(),
		.qe(),
		.q(),
		.qs(classc_state_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_classd_ctrl_en(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(classd_ctrl_en_we & regen_qs),
		.wd(classd_ctrl_en_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[191]),
		.qs(classd_ctrl_en_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_classd_ctrl_lock(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(classd_ctrl_lock_we & regen_qs),
		.wd(classd_ctrl_lock_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[190]),
		.qs(classd_ctrl_lock_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h1)
	) u_classd_ctrl_en_e0(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(classd_ctrl_en_e0_we & regen_qs),
		.wd(classd_ctrl_en_e0_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[189]),
		.qs(classd_ctrl_en_e0_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h1)
	) u_classd_ctrl_en_e1(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(classd_ctrl_en_e1_we & regen_qs),
		.wd(classd_ctrl_en_e1_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[188]),
		.qs(classd_ctrl_en_e1_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h1)
	) u_classd_ctrl_en_e2(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(classd_ctrl_en_e2_we & regen_qs),
		.wd(classd_ctrl_en_e2_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[187]),
		.qs(classd_ctrl_en_e2_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h1)
	) u_classd_ctrl_en_e3(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(classd_ctrl_en_e3_we & regen_qs),
		.wd(classd_ctrl_en_e3_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[186]),
		.qs(classd_ctrl_en_e3_qs)
	);
	prim_subreg #(
		.DW(2),
		.SWACCESS("RW"),
		.RESVAL(2'h0)
	) u_classd_ctrl_map_e0(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(classd_ctrl_map_e0_we & regen_qs),
		.wd(classd_ctrl_map_e0_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[185-:2]),
		.qs(classd_ctrl_map_e0_qs)
	);
	prim_subreg #(
		.DW(2),
		.SWACCESS("RW"),
		.RESVAL(2'h1)
	) u_classd_ctrl_map_e1(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(classd_ctrl_map_e1_we & regen_qs),
		.wd(classd_ctrl_map_e1_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[183-:2]),
		.qs(classd_ctrl_map_e1_qs)
	);
	prim_subreg #(
		.DW(2),
		.SWACCESS("RW"),
		.RESVAL(2'h2)
	) u_classd_ctrl_map_e2(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(classd_ctrl_map_e2_we & regen_qs),
		.wd(classd_ctrl_map_e2_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[181-:2]),
		.qs(classd_ctrl_map_e2_qs)
	);
	prim_subreg #(
		.DW(2),
		.SWACCESS("RW"),
		.RESVAL(2'h3)
	) u_classd_ctrl_map_e3(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(classd_ctrl_map_e3_we & regen_qs),
		.wd(classd_ctrl_map_e3_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[179-:2]),
		.qs(classd_ctrl_map_e3_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("W1C"),
		.RESVAL(1'h1)
	) u_classd_clren(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(classd_clren_we),
		.wd(classd_clren_wd),
		.de(hw2reg[51]),
		.d(hw2reg[52]),
		.qe(),
		.q(),
		.qs(classd_clren_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("WO"),
		.RESVAL(1'h0)
	) u_classd_clr(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(classd_clr_we & classd_clren_qs),
		.wd(classd_clr_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(reg2hw[176]),
		.q(reg2hw[177]),
		.qs()
	);
	prim_subreg_ext #(.DW(16)) u_classd_accum_cnt(
		.re(classd_accum_cnt_re),
		.we(1'b0),
		.wd(1'sb0),
		.d(hw2reg[50-:16]),
		.qre(),
		.qe(),
		.q(),
		.qs(classd_accum_cnt_qs)
	);
	prim_subreg #(
		.DW(16),
		.SWACCESS("RW"),
		.RESVAL(16'h0)
	) u_classd_accum_thresh(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(classd_accum_thresh_we & regen_qs),
		.wd(classd_accum_thresh_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[175-:16]),
		.qs(classd_accum_thresh_qs)
	);
	prim_subreg #(
		.DW(32),
		.SWACCESS("RW"),
		.RESVAL(32'h0)
	) u_classd_timeout_cyc(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(classd_timeout_cyc_we & regen_qs),
		.wd(classd_timeout_cyc_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[159-:32]),
		.qs(classd_timeout_cyc_qs)
	);
	prim_subreg #(
		.DW(32),
		.SWACCESS("RW"),
		.RESVAL(32'h0)
	) u_classd_phase0_cyc(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(classd_phase0_cyc_we & regen_qs),
		.wd(classd_phase0_cyc_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[127-:32]),
		.qs(classd_phase0_cyc_qs)
	);
	prim_subreg #(
		.DW(32),
		.SWACCESS("RW"),
		.RESVAL(32'h0)
	) u_classd_phase1_cyc(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(classd_phase1_cyc_we & regen_qs),
		.wd(classd_phase1_cyc_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[95-:32]),
		.qs(classd_phase1_cyc_qs)
	);
	prim_subreg #(
		.DW(32),
		.SWACCESS("RW"),
		.RESVAL(32'h0)
	) u_classd_phase2_cyc(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(classd_phase2_cyc_we & regen_qs),
		.wd(classd_phase2_cyc_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[63-:32]),
		.qs(classd_phase2_cyc_qs)
	);
	prim_subreg #(
		.DW(32),
		.SWACCESS("RW"),
		.RESVAL(32'h0)
	) u_classd_phase3_cyc(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(classd_phase3_cyc_we & regen_qs),
		.wd(classd_phase3_cyc_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[31-:32]),
		.qs(classd_phase3_cyc_qs)
	);
	prim_subreg_ext #(.DW(32)) u_classd_esc_cnt(
		.re(classd_esc_cnt_re),
		.we(1'b0),
		.wd(1'sb0),
		.d(hw2reg[34-:32]),
		.qre(),
		.qe(),
		.q(),
		.qs(classd_esc_cnt_qs)
	);
	prim_subreg_ext #(.DW(3)) u_classd_state(
		.re(classd_state_re),
		.we(1'b0),
		.wd(1'sb0),
		.d(hw2reg[2-:3]),
		.qre(),
		.qe(),
		.q(),
		.qs(classd_state_qs)
	);
	reg [58:0] addr_hit;
	always @(*) begin
		addr_hit = 1'sb0;
		addr_hit[0] = reg_addr == ALERT_HANDLER_INTR_STATE_OFFSET;
		addr_hit[1] = reg_addr == ALERT_HANDLER_INTR_ENABLE_OFFSET;
		addr_hit[2] = reg_addr == ALERT_HANDLER_INTR_TEST_OFFSET;
		addr_hit[3] = reg_addr == ALERT_HANDLER_REGEN_OFFSET;
		addr_hit[4] = reg_addr == ALERT_HANDLER_PING_TIMEOUT_CYC_OFFSET;
		addr_hit[5] = reg_addr == ALERT_HANDLER_ALERT_EN_OFFSET;
		addr_hit[6] = reg_addr == ALERT_HANDLER_ALERT_CLASS_OFFSET;
		addr_hit[7] = reg_addr == ALERT_HANDLER_ALERT_CAUSE_OFFSET;
		addr_hit[8] = reg_addr == ALERT_HANDLER_LOC_ALERT_EN_OFFSET;
		addr_hit[9] = reg_addr == ALERT_HANDLER_LOC_ALERT_CLASS_OFFSET;
		addr_hit[10] = reg_addr == ALERT_HANDLER_LOC_ALERT_CAUSE_OFFSET;
		addr_hit[11] = reg_addr == ALERT_HANDLER_CLASSA_CTRL_OFFSET;
		addr_hit[12] = reg_addr == ALERT_HANDLER_CLASSA_CLREN_OFFSET;
		addr_hit[13] = reg_addr == ALERT_HANDLER_CLASSA_CLR_OFFSET;
		addr_hit[14] = reg_addr == ALERT_HANDLER_CLASSA_ACCUM_CNT_OFFSET;
		addr_hit[15] = reg_addr == ALERT_HANDLER_CLASSA_ACCUM_THRESH_OFFSET;
		addr_hit[16] = reg_addr == ALERT_HANDLER_CLASSA_TIMEOUT_CYC_OFFSET;
		addr_hit[17] = reg_addr == ALERT_HANDLER_CLASSA_PHASE0_CYC_OFFSET;
		addr_hit[18] = reg_addr == ALERT_HANDLER_CLASSA_PHASE1_CYC_OFFSET;
		addr_hit[19] = reg_addr == ALERT_HANDLER_CLASSA_PHASE2_CYC_OFFSET;
		addr_hit[20] = reg_addr == ALERT_HANDLER_CLASSA_PHASE3_CYC_OFFSET;
		addr_hit[21] = reg_addr == ALERT_HANDLER_CLASSA_ESC_CNT_OFFSET;
		addr_hit[22] = reg_addr == ALERT_HANDLER_CLASSA_STATE_OFFSET;
		addr_hit[23] = reg_addr == ALERT_HANDLER_CLASSB_CTRL_OFFSET;
		addr_hit[24] = reg_addr == ALERT_HANDLER_CLASSB_CLREN_OFFSET;
		addr_hit[25] = reg_addr == ALERT_HANDLER_CLASSB_CLR_OFFSET;
		addr_hit[26] = reg_addr == ALERT_HANDLER_CLASSB_ACCUM_CNT_OFFSET;
		addr_hit[27] = reg_addr == ALERT_HANDLER_CLASSB_ACCUM_THRESH_OFFSET;
		addr_hit[28] = reg_addr == ALERT_HANDLER_CLASSB_TIMEOUT_CYC_OFFSET;
		addr_hit[29] = reg_addr == ALERT_HANDLER_CLASSB_PHASE0_CYC_OFFSET;
		addr_hit[30] = reg_addr == ALERT_HANDLER_CLASSB_PHASE1_CYC_OFFSET;
		addr_hit[31] = reg_addr == ALERT_HANDLER_CLASSB_PHASE2_CYC_OFFSET;
		addr_hit[32] = reg_addr == ALERT_HANDLER_CLASSB_PHASE3_CYC_OFFSET;
		addr_hit[33] = reg_addr == ALERT_HANDLER_CLASSB_ESC_CNT_OFFSET;
		addr_hit[34] = reg_addr == ALERT_HANDLER_CLASSB_STATE_OFFSET;
		addr_hit[35] = reg_addr == ALERT_HANDLER_CLASSC_CTRL_OFFSET;
		addr_hit[36] = reg_addr == ALERT_HANDLER_CLASSC_CLREN_OFFSET;
		addr_hit[37] = reg_addr == ALERT_HANDLER_CLASSC_CLR_OFFSET;
		addr_hit[38] = reg_addr == ALERT_HANDLER_CLASSC_ACCUM_CNT_OFFSET;
		addr_hit[39] = reg_addr == ALERT_HANDLER_CLASSC_ACCUM_THRESH_OFFSET;
		addr_hit[40] = reg_addr == ALERT_HANDLER_CLASSC_TIMEOUT_CYC_OFFSET;
		addr_hit[41] = reg_addr == ALERT_HANDLER_CLASSC_PHASE0_CYC_OFFSET;
		addr_hit[42] = reg_addr == ALERT_HANDLER_CLASSC_PHASE1_CYC_OFFSET;
		addr_hit[43] = reg_addr == ALERT_HANDLER_CLASSC_PHASE2_CYC_OFFSET;
		addr_hit[44] = reg_addr == ALERT_HANDLER_CLASSC_PHASE3_CYC_OFFSET;
		addr_hit[45] = reg_addr == ALERT_HANDLER_CLASSC_ESC_CNT_OFFSET;
		addr_hit[46] = reg_addr == ALERT_HANDLER_CLASSC_STATE_OFFSET;
		addr_hit[47] = reg_addr == ALERT_HANDLER_CLASSD_CTRL_OFFSET;
		addr_hit[48] = reg_addr == ALERT_HANDLER_CLASSD_CLREN_OFFSET;
		addr_hit[49] = reg_addr == ALERT_HANDLER_CLASSD_CLR_OFFSET;
		addr_hit[50] = reg_addr == ALERT_HANDLER_CLASSD_ACCUM_CNT_OFFSET;
		addr_hit[51] = reg_addr == ALERT_HANDLER_CLASSD_ACCUM_THRESH_OFFSET;
		addr_hit[52] = reg_addr == ALERT_HANDLER_CLASSD_TIMEOUT_CYC_OFFSET;
		addr_hit[53] = reg_addr == ALERT_HANDLER_CLASSD_PHASE0_CYC_OFFSET;
		addr_hit[54] = reg_addr == ALERT_HANDLER_CLASSD_PHASE1_CYC_OFFSET;
		addr_hit[55] = reg_addr == ALERT_HANDLER_CLASSD_PHASE2_CYC_OFFSET;
		addr_hit[56] = reg_addr == ALERT_HANDLER_CLASSD_PHASE3_CYC_OFFSET;
		addr_hit[57] = reg_addr == ALERT_HANDLER_CLASSD_ESC_CNT_OFFSET;
		addr_hit[58] = reg_addr == ALERT_HANDLER_CLASSD_STATE_OFFSET;
	end
	assign addrmiss = (reg_re || reg_we ? ~|addr_hit : 1'b0);
	always @(*) begin
		wr_err = 1'b0;
		if ((addr_hit[0] && reg_we) && (ALERT_HANDLER_PERMIT[232+:4] != (ALERT_HANDLER_PERMIT[232+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[1] && reg_we) && (ALERT_HANDLER_PERMIT[228+:4] != (ALERT_HANDLER_PERMIT[228+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[2] && reg_we) && (ALERT_HANDLER_PERMIT[224+:4] != (ALERT_HANDLER_PERMIT[224+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[3] && reg_we) && (ALERT_HANDLER_PERMIT[220+:4] != (ALERT_HANDLER_PERMIT[220+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[4] && reg_we) && (ALERT_HANDLER_PERMIT[216+:4] != (ALERT_HANDLER_PERMIT[216+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[5] && reg_we) && (ALERT_HANDLER_PERMIT[212+:4] != (ALERT_HANDLER_PERMIT[212+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[6] && reg_we) && (ALERT_HANDLER_PERMIT[208+:4] != (ALERT_HANDLER_PERMIT[208+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[7] && reg_we) && (ALERT_HANDLER_PERMIT[204+:4] != (ALERT_HANDLER_PERMIT[204+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[8] && reg_we) && (ALERT_HANDLER_PERMIT[200+:4] != (ALERT_HANDLER_PERMIT[200+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[9] && reg_we) && (ALERT_HANDLER_PERMIT[196+:4] != (ALERT_HANDLER_PERMIT[196+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[10] && reg_we) && (ALERT_HANDLER_PERMIT[192+:4] != (ALERT_HANDLER_PERMIT[192+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[11] && reg_we) && (ALERT_HANDLER_PERMIT[188+:4] != (ALERT_HANDLER_PERMIT[188+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[12] && reg_we) && (ALERT_HANDLER_PERMIT[184+:4] != (ALERT_HANDLER_PERMIT[184+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[13] && reg_we) && (ALERT_HANDLER_PERMIT[180+:4] != (ALERT_HANDLER_PERMIT[180+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[14] && reg_we) && (ALERT_HANDLER_PERMIT[176+:4] != (ALERT_HANDLER_PERMIT[176+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[15] && reg_we) && (ALERT_HANDLER_PERMIT[172+:4] != (ALERT_HANDLER_PERMIT[172+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[16] && reg_we) && (ALERT_HANDLER_PERMIT[168+:4] != (ALERT_HANDLER_PERMIT[168+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[17] && reg_we) && (ALERT_HANDLER_PERMIT[164+:4] != (ALERT_HANDLER_PERMIT[164+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[18] && reg_we) && (ALERT_HANDLER_PERMIT[160+:4] != (ALERT_HANDLER_PERMIT[160+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[19] && reg_we) && (ALERT_HANDLER_PERMIT[156+:4] != (ALERT_HANDLER_PERMIT[156+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[20] && reg_we) && (ALERT_HANDLER_PERMIT[152+:4] != (ALERT_HANDLER_PERMIT[152+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[21] && reg_we) && (ALERT_HANDLER_PERMIT[148+:4] != (ALERT_HANDLER_PERMIT[148+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[22] && reg_we) && (ALERT_HANDLER_PERMIT[144+:4] != (ALERT_HANDLER_PERMIT[144+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[23] && reg_we) && (ALERT_HANDLER_PERMIT[140+:4] != (ALERT_HANDLER_PERMIT[140+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[24] && reg_we) && (ALERT_HANDLER_PERMIT[136+:4] != (ALERT_HANDLER_PERMIT[136+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[25] && reg_we) && (ALERT_HANDLER_PERMIT[132+:4] != (ALERT_HANDLER_PERMIT[132+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[26] && reg_we) && (ALERT_HANDLER_PERMIT[128+:4] != (ALERT_HANDLER_PERMIT[128+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[27] && reg_we) && (ALERT_HANDLER_PERMIT[124+:4] != (ALERT_HANDLER_PERMIT[124+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[28] && reg_we) && (ALERT_HANDLER_PERMIT[120+:4] != (ALERT_HANDLER_PERMIT[120+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[29] && reg_we) && (ALERT_HANDLER_PERMIT[116+:4] != (ALERT_HANDLER_PERMIT[116+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[30] && reg_we) && (ALERT_HANDLER_PERMIT[112+:4] != (ALERT_HANDLER_PERMIT[112+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[31] && reg_we) && (ALERT_HANDLER_PERMIT[108+:4] != (ALERT_HANDLER_PERMIT[108+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[32] && reg_we) && (ALERT_HANDLER_PERMIT[104+:4] != (ALERT_HANDLER_PERMIT[104+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[33] && reg_we) && (ALERT_HANDLER_PERMIT[100+:4] != (ALERT_HANDLER_PERMIT[100+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[34] && reg_we) && (ALERT_HANDLER_PERMIT[96+:4] != (ALERT_HANDLER_PERMIT[96+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[35] && reg_we) && (ALERT_HANDLER_PERMIT[92+:4] != (ALERT_HANDLER_PERMIT[92+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[36] && reg_we) && (ALERT_HANDLER_PERMIT[88+:4] != (ALERT_HANDLER_PERMIT[88+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[37] && reg_we) && (ALERT_HANDLER_PERMIT[84+:4] != (ALERT_HANDLER_PERMIT[84+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[38] && reg_we) && (ALERT_HANDLER_PERMIT[80+:4] != (ALERT_HANDLER_PERMIT[80+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[39] && reg_we) && (ALERT_HANDLER_PERMIT[76+:4] != (ALERT_HANDLER_PERMIT[76+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[40] && reg_we) && (ALERT_HANDLER_PERMIT[72+:4] != (ALERT_HANDLER_PERMIT[72+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[41] && reg_we) && (ALERT_HANDLER_PERMIT[68+:4] != (ALERT_HANDLER_PERMIT[68+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[42] && reg_we) && (ALERT_HANDLER_PERMIT[64+:4] != (ALERT_HANDLER_PERMIT[64+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[43] && reg_we) && (ALERT_HANDLER_PERMIT[60+:4] != (ALERT_HANDLER_PERMIT[60+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[44] && reg_we) && (ALERT_HANDLER_PERMIT[56+:4] != (ALERT_HANDLER_PERMIT[56+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[45] && reg_we) && (ALERT_HANDLER_PERMIT[52+:4] != (ALERT_HANDLER_PERMIT[52+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[46] && reg_we) && (ALERT_HANDLER_PERMIT[48+:4] != (ALERT_HANDLER_PERMIT[48+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[47] && reg_we) && (ALERT_HANDLER_PERMIT[44+:4] != (ALERT_HANDLER_PERMIT[44+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[48] && reg_we) && (ALERT_HANDLER_PERMIT[40+:4] != (ALERT_HANDLER_PERMIT[40+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[49] && reg_we) && (ALERT_HANDLER_PERMIT[36+:4] != (ALERT_HANDLER_PERMIT[36+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[50] && reg_we) && (ALERT_HANDLER_PERMIT[32+:4] != (ALERT_HANDLER_PERMIT[32+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[51] && reg_we) && (ALERT_HANDLER_PERMIT[28+:4] != (ALERT_HANDLER_PERMIT[28+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[52] && reg_we) && (ALERT_HANDLER_PERMIT[24+:4] != (ALERT_HANDLER_PERMIT[24+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[53] && reg_we) && (ALERT_HANDLER_PERMIT[20+:4] != (ALERT_HANDLER_PERMIT[20+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[54] && reg_we) && (ALERT_HANDLER_PERMIT[16+:4] != (ALERT_HANDLER_PERMIT[16+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[55] && reg_we) && (ALERT_HANDLER_PERMIT[12+:4] != (ALERT_HANDLER_PERMIT[12+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[56] && reg_we) && (ALERT_HANDLER_PERMIT[8+:4] != (ALERT_HANDLER_PERMIT[8+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[57] && reg_we) && (ALERT_HANDLER_PERMIT[4+:4] != (ALERT_HANDLER_PERMIT[4+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[58] && reg_we) && (ALERT_HANDLER_PERMIT[0+:4] != (ALERT_HANDLER_PERMIT[0+:4] & reg_be)))
			wr_err = 1'b1;
	end
	assign intr_state_classa_we = (addr_hit[0] & reg_we) & ~wr_err;
	assign intr_state_classa_wd = reg_wdata[0];
	assign intr_state_classb_we = (addr_hit[0] & reg_we) & ~wr_err;
	assign intr_state_classb_wd = reg_wdata[1];
	assign intr_state_classc_we = (addr_hit[0] & reg_we) & ~wr_err;
	assign intr_state_classc_wd = reg_wdata[2];
	assign intr_state_classd_we = (addr_hit[0] & reg_we) & ~wr_err;
	assign intr_state_classd_wd = reg_wdata[3];
	assign intr_enable_classa_we = (addr_hit[1] & reg_we) & ~wr_err;
	assign intr_enable_classa_wd = reg_wdata[0];
	assign intr_enable_classb_we = (addr_hit[1] & reg_we) & ~wr_err;
	assign intr_enable_classb_wd = reg_wdata[1];
	assign intr_enable_classc_we = (addr_hit[1] & reg_we) & ~wr_err;
	assign intr_enable_classc_wd = reg_wdata[2];
	assign intr_enable_classd_we = (addr_hit[1] & reg_we) & ~wr_err;
	assign intr_enable_classd_wd = reg_wdata[3];
	assign intr_test_classa_we = (addr_hit[2] & reg_we) & ~wr_err;
	assign intr_test_classa_wd = reg_wdata[0];
	assign intr_test_classb_we = (addr_hit[2] & reg_we) & ~wr_err;
	assign intr_test_classb_wd = reg_wdata[1];
	assign intr_test_classc_we = (addr_hit[2] & reg_we) & ~wr_err;
	assign intr_test_classc_wd = reg_wdata[2];
	assign intr_test_classd_we = (addr_hit[2] & reg_we) & ~wr_err;
	assign intr_test_classd_wd = reg_wdata[3];
	assign regen_we = (addr_hit[3] & reg_we) & ~wr_err;
	assign regen_wd = reg_wdata[0];
	assign ping_timeout_cyc_we = (addr_hit[4] & reg_we) & ~wr_err;
	assign ping_timeout_cyc_wd = reg_wdata[23:0];
	assign alert_en_we = (addr_hit[5] & reg_we) & ~wr_err;
	assign alert_en_wd = reg_wdata[0];
	assign alert_class_we = (addr_hit[6] & reg_we) & ~wr_err;
	assign alert_class_wd = reg_wdata[1:0];
	assign alert_cause_we = (addr_hit[7] & reg_we) & ~wr_err;
	assign alert_cause_wd = reg_wdata[0];
	assign loc_alert_en_en_la0_we = (addr_hit[8] & reg_we) & ~wr_err;
	assign loc_alert_en_en_la0_wd = reg_wdata[0];
	assign loc_alert_en_en_la1_we = (addr_hit[8] & reg_we) & ~wr_err;
	assign loc_alert_en_en_la1_wd = reg_wdata[1];
	assign loc_alert_en_en_la2_we = (addr_hit[8] & reg_we) & ~wr_err;
	assign loc_alert_en_en_la2_wd = reg_wdata[2];
	assign loc_alert_en_en_la3_we = (addr_hit[8] & reg_we) & ~wr_err;
	assign loc_alert_en_en_la3_wd = reg_wdata[3];
	assign loc_alert_class_class_la0_we = (addr_hit[9] & reg_we) & ~wr_err;
	assign loc_alert_class_class_la0_wd = reg_wdata[1:0];
	assign loc_alert_class_class_la1_we = (addr_hit[9] & reg_we) & ~wr_err;
	assign loc_alert_class_class_la1_wd = reg_wdata[3:2];
	assign loc_alert_class_class_la2_we = (addr_hit[9] & reg_we) & ~wr_err;
	assign loc_alert_class_class_la2_wd = reg_wdata[5:4];
	assign loc_alert_class_class_la3_we = (addr_hit[9] & reg_we) & ~wr_err;
	assign loc_alert_class_class_la3_wd = reg_wdata[7:6];
	assign loc_alert_cause_la0_we = (addr_hit[10] & reg_we) & ~wr_err;
	assign loc_alert_cause_la0_wd = reg_wdata[0];
	assign loc_alert_cause_la1_we = (addr_hit[10] & reg_we) & ~wr_err;
	assign loc_alert_cause_la1_wd = reg_wdata[1];
	assign loc_alert_cause_la2_we = (addr_hit[10] & reg_we) & ~wr_err;
	assign loc_alert_cause_la2_wd = reg_wdata[2];
	assign loc_alert_cause_la3_we = (addr_hit[10] & reg_we) & ~wr_err;
	assign loc_alert_cause_la3_wd = reg_wdata[3];
	assign classa_ctrl_en_we = (addr_hit[11] & reg_we) & ~wr_err;
	assign classa_ctrl_en_wd = reg_wdata[0];
	assign classa_ctrl_lock_we = (addr_hit[11] & reg_we) & ~wr_err;
	assign classa_ctrl_lock_wd = reg_wdata[1];
	assign classa_ctrl_en_e0_we = (addr_hit[11] & reg_we) & ~wr_err;
	assign classa_ctrl_en_e0_wd = reg_wdata[2];
	assign classa_ctrl_en_e1_we = (addr_hit[11] & reg_we) & ~wr_err;
	assign classa_ctrl_en_e1_wd = reg_wdata[3];
	assign classa_ctrl_en_e2_we = (addr_hit[11] & reg_we) & ~wr_err;
	assign classa_ctrl_en_e2_wd = reg_wdata[4];
	assign classa_ctrl_en_e3_we = (addr_hit[11] & reg_we) & ~wr_err;
	assign classa_ctrl_en_e3_wd = reg_wdata[5];
	assign classa_ctrl_map_e0_we = (addr_hit[11] & reg_we) & ~wr_err;
	assign classa_ctrl_map_e0_wd = reg_wdata[7:6];
	assign classa_ctrl_map_e1_we = (addr_hit[11] & reg_we) & ~wr_err;
	assign classa_ctrl_map_e1_wd = reg_wdata[9:8];
	assign classa_ctrl_map_e2_we = (addr_hit[11] & reg_we) & ~wr_err;
	assign classa_ctrl_map_e2_wd = reg_wdata[11:10];
	assign classa_ctrl_map_e3_we = (addr_hit[11] & reg_we) & ~wr_err;
	assign classa_ctrl_map_e3_wd = reg_wdata[13:12];
	assign classa_clren_we = (addr_hit[12] & reg_we) & ~wr_err;
	assign classa_clren_wd = reg_wdata[0];
	assign classa_clr_we = (addr_hit[13] & reg_we) & ~wr_err;
	assign classa_clr_wd = reg_wdata[0];
	assign classa_accum_cnt_re = addr_hit[14] && reg_re;
	assign classa_accum_thresh_we = (addr_hit[15] & reg_we) & ~wr_err;
	assign classa_accum_thresh_wd = reg_wdata[15:0];
	assign classa_timeout_cyc_we = (addr_hit[16] & reg_we) & ~wr_err;
	assign classa_timeout_cyc_wd = reg_wdata[31:0];
	assign classa_phase0_cyc_we = (addr_hit[17] & reg_we) & ~wr_err;
	assign classa_phase0_cyc_wd = reg_wdata[31:0];
	assign classa_phase1_cyc_we = (addr_hit[18] & reg_we) & ~wr_err;
	assign classa_phase1_cyc_wd = reg_wdata[31:0];
	assign classa_phase2_cyc_we = (addr_hit[19] & reg_we) & ~wr_err;
	assign classa_phase2_cyc_wd = reg_wdata[31:0];
	assign classa_phase3_cyc_we = (addr_hit[20] & reg_we) & ~wr_err;
	assign classa_phase3_cyc_wd = reg_wdata[31:0];
	assign classa_esc_cnt_re = addr_hit[21] && reg_re;
	assign classa_state_re = addr_hit[22] && reg_re;
	assign classb_ctrl_en_we = (addr_hit[23] & reg_we) & ~wr_err;
	assign classb_ctrl_en_wd = reg_wdata[0];
	assign classb_ctrl_lock_we = (addr_hit[23] & reg_we) & ~wr_err;
	assign classb_ctrl_lock_wd = reg_wdata[1];
	assign classb_ctrl_en_e0_we = (addr_hit[23] & reg_we) & ~wr_err;
	assign classb_ctrl_en_e0_wd = reg_wdata[2];
	assign classb_ctrl_en_e1_we = (addr_hit[23] & reg_we) & ~wr_err;
	assign classb_ctrl_en_e1_wd = reg_wdata[3];
	assign classb_ctrl_en_e2_we = (addr_hit[23] & reg_we) & ~wr_err;
	assign classb_ctrl_en_e2_wd = reg_wdata[4];
	assign classb_ctrl_en_e3_we = (addr_hit[23] & reg_we) & ~wr_err;
	assign classb_ctrl_en_e3_wd = reg_wdata[5];
	assign classb_ctrl_map_e0_we = (addr_hit[23] & reg_we) & ~wr_err;
	assign classb_ctrl_map_e0_wd = reg_wdata[7:6];
	assign classb_ctrl_map_e1_we = (addr_hit[23] & reg_we) & ~wr_err;
	assign classb_ctrl_map_e1_wd = reg_wdata[9:8];
	assign classb_ctrl_map_e2_we = (addr_hit[23] & reg_we) & ~wr_err;
	assign classb_ctrl_map_e2_wd = reg_wdata[11:10];
	assign classb_ctrl_map_e3_we = (addr_hit[23] & reg_we) & ~wr_err;
	assign classb_ctrl_map_e3_wd = reg_wdata[13:12];
	assign classb_clren_we = (addr_hit[24] & reg_we) & ~wr_err;
	assign classb_clren_wd = reg_wdata[0];
	assign classb_clr_we = (addr_hit[25] & reg_we) & ~wr_err;
	assign classb_clr_wd = reg_wdata[0];
	assign classb_accum_cnt_re = addr_hit[26] && reg_re;
	assign classb_accum_thresh_we = (addr_hit[27] & reg_we) & ~wr_err;
	assign classb_accum_thresh_wd = reg_wdata[15:0];
	assign classb_timeout_cyc_we = (addr_hit[28] & reg_we) & ~wr_err;
	assign classb_timeout_cyc_wd = reg_wdata[31:0];
	assign classb_phase0_cyc_we = (addr_hit[29] & reg_we) & ~wr_err;
	assign classb_phase0_cyc_wd = reg_wdata[31:0];
	assign classb_phase1_cyc_we = (addr_hit[30] & reg_we) & ~wr_err;
	assign classb_phase1_cyc_wd = reg_wdata[31:0];
	assign classb_phase2_cyc_we = (addr_hit[31] & reg_we) & ~wr_err;
	assign classb_phase2_cyc_wd = reg_wdata[31:0];
	assign classb_phase3_cyc_we = (addr_hit[32] & reg_we) & ~wr_err;
	assign classb_phase3_cyc_wd = reg_wdata[31:0];
	assign classb_esc_cnt_re = addr_hit[33] && reg_re;
	assign classb_state_re = addr_hit[34] && reg_re;
	assign classc_ctrl_en_we = (addr_hit[35] & reg_we) & ~wr_err;
	assign classc_ctrl_en_wd = reg_wdata[0];
	assign classc_ctrl_lock_we = (addr_hit[35] & reg_we) & ~wr_err;
	assign classc_ctrl_lock_wd = reg_wdata[1];
	assign classc_ctrl_en_e0_we = (addr_hit[35] & reg_we) & ~wr_err;
	assign classc_ctrl_en_e0_wd = reg_wdata[2];
	assign classc_ctrl_en_e1_we = (addr_hit[35] & reg_we) & ~wr_err;
	assign classc_ctrl_en_e1_wd = reg_wdata[3];
	assign classc_ctrl_en_e2_we = (addr_hit[35] & reg_we) & ~wr_err;
	assign classc_ctrl_en_e2_wd = reg_wdata[4];
	assign classc_ctrl_en_e3_we = (addr_hit[35] & reg_we) & ~wr_err;
	assign classc_ctrl_en_e3_wd = reg_wdata[5];
	assign classc_ctrl_map_e0_we = (addr_hit[35] & reg_we) & ~wr_err;
	assign classc_ctrl_map_e0_wd = reg_wdata[7:6];
	assign classc_ctrl_map_e1_we = (addr_hit[35] & reg_we) & ~wr_err;
	assign classc_ctrl_map_e1_wd = reg_wdata[9:8];
	assign classc_ctrl_map_e2_we = (addr_hit[35] & reg_we) & ~wr_err;
	assign classc_ctrl_map_e2_wd = reg_wdata[11:10];
	assign classc_ctrl_map_e3_we = (addr_hit[35] & reg_we) & ~wr_err;
	assign classc_ctrl_map_e3_wd = reg_wdata[13:12];
	assign classc_clren_we = (addr_hit[36] & reg_we) & ~wr_err;
	assign classc_clren_wd = reg_wdata[0];
	assign classc_clr_we = (addr_hit[37] & reg_we) & ~wr_err;
	assign classc_clr_wd = reg_wdata[0];
	assign classc_accum_cnt_re = addr_hit[38] && reg_re;
	assign classc_accum_thresh_we = (addr_hit[39] & reg_we) & ~wr_err;
	assign classc_accum_thresh_wd = reg_wdata[15:0];
	assign classc_timeout_cyc_we = (addr_hit[40] & reg_we) & ~wr_err;
	assign classc_timeout_cyc_wd = reg_wdata[31:0];
	assign classc_phase0_cyc_we = (addr_hit[41] & reg_we) & ~wr_err;
	assign classc_phase0_cyc_wd = reg_wdata[31:0];
	assign classc_phase1_cyc_we = (addr_hit[42] & reg_we) & ~wr_err;
	assign classc_phase1_cyc_wd = reg_wdata[31:0];
	assign classc_phase2_cyc_we = (addr_hit[43] & reg_we) & ~wr_err;
	assign classc_phase2_cyc_wd = reg_wdata[31:0];
	assign classc_phase3_cyc_we = (addr_hit[44] & reg_we) & ~wr_err;
	assign classc_phase3_cyc_wd = reg_wdata[31:0];
	assign classc_esc_cnt_re = addr_hit[45] && reg_re;
	assign classc_state_re = addr_hit[46] && reg_re;
	assign classd_ctrl_en_we = (addr_hit[47] & reg_we) & ~wr_err;
	assign classd_ctrl_en_wd = reg_wdata[0];
	assign classd_ctrl_lock_we = (addr_hit[47] & reg_we) & ~wr_err;
	assign classd_ctrl_lock_wd = reg_wdata[1];
	assign classd_ctrl_en_e0_we = (addr_hit[47] & reg_we) & ~wr_err;
	assign classd_ctrl_en_e0_wd = reg_wdata[2];
	assign classd_ctrl_en_e1_we = (addr_hit[47] & reg_we) & ~wr_err;
	assign classd_ctrl_en_e1_wd = reg_wdata[3];
	assign classd_ctrl_en_e2_we = (addr_hit[47] & reg_we) & ~wr_err;
	assign classd_ctrl_en_e2_wd = reg_wdata[4];
	assign classd_ctrl_en_e3_we = (addr_hit[47] & reg_we) & ~wr_err;
	assign classd_ctrl_en_e3_wd = reg_wdata[5];
	assign classd_ctrl_map_e0_we = (addr_hit[47] & reg_we) & ~wr_err;
	assign classd_ctrl_map_e0_wd = reg_wdata[7:6];
	assign classd_ctrl_map_e1_we = (addr_hit[47] & reg_we) & ~wr_err;
	assign classd_ctrl_map_e1_wd = reg_wdata[9:8];
	assign classd_ctrl_map_e2_we = (addr_hit[47] & reg_we) & ~wr_err;
	assign classd_ctrl_map_e2_wd = reg_wdata[11:10];
	assign classd_ctrl_map_e3_we = (addr_hit[47] & reg_we) & ~wr_err;
	assign classd_ctrl_map_e3_wd = reg_wdata[13:12];
	assign classd_clren_we = (addr_hit[48] & reg_we) & ~wr_err;
	assign classd_clren_wd = reg_wdata[0];
	assign classd_clr_we = (addr_hit[49] & reg_we) & ~wr_err;
	assign classd_clr_wd = reg_wdata[0];
	assign classd_accum_cnt_re = addr_hit[50] && reg_re;
	assign classd_accum_thresh_we = (addr_hit[51] & reg_we) & ~wr_err;
	assign classd_accum_thresh_wd = reg_wdata[15:0];
	assign classd_timeout_cyc_we = (addr_hit[52] & reg_we) & ~wr_err;
	assign classd_timeout_cyc_wd = reg_wdata[31:0];
	assign classd_phase0_cyc_we = (addr_hit[53] & reg_we) & ~wr_err;
	assign classd_phase0_cyc_wd = reg_wdata[31:0];
	assign classd_phase1_cyc_we = (addr_hit[54] & reg_we) & ~wr_err;
	assign classd_phase1_cyc_wd = reg_wdata[31:0];
	assign classd_phase2_cyc_we = (addr_hit[55] & reg_we) & ~wr_err;
	assign classd_phase2_cyc_wd = reg_wdata[31:0];
	assign classd_phase3_cyc_we = (addr_hit[56] & reg_we) & ~wr_err;
	assign classd_phase3_cyc_wd = reg_wdata[31:0];
	assign classd_esc_cnt_re = addr_hit[57] && reg_re;
	assign classd_state_re = addr_hit[58] && reg_re;
	always @(*) begin
		reg_rdata_next = 1'sb0;
		case (1'b1)
			addr_hit[0]: begin
				reg_rdata_next[0] = intr_state_classa_qs;
				reg_rdata_next[1] = intr_state_classb_qs;
				reg_rdata_next[2] = intr_state_classc_qs;
				reg_rdata_next[3] = intr_state_classd_qs;
			end
			addr_hit[1]: begin
				reg_rdata_next[0] = intr_enable_classa_qs;
				reg_rdata_next[1] = intr_enable_classb_qs;
				reg_rdata_next[2] = intr_enable_classc_qs;
				reg_rdata_next[3] = intr_enable_classd_qs;
			end
			addr_hit[2]: begin
				reg_rdata_next[0] = 1'sb0;
				reg_rdata_next[1] = 1'sb0;
				reg_rdata_next[2] = 1'sb0;
				reg_rdata_next[3] = 1'sb0;
			end
			addr_hit[3]: reg_rdata_next[0] = regen_qs;
			addr_hit[4]: reg_rdata_next[23:0] = ping_timeout_cyc_qs;
			addr_hit[5]: reg_rdata_next[0] = alert_en_qs;
			addr_hit[6]: reg_rdata_next[1:0] = alert_class_qs;
			addr_hit[7]: reg_rdata_next[0] = alert_cause_qs;
			addr_hit[8]: begin
				reg_rdata_next[0] = loc_alert_en_en_la0_qs;
				reg_rdata_next[1] = loc_alert_en_en_la1_qs;
				reg_rdata_next[2] = loc_alert_en_en_la2_qs;
				reg_rdata_next[3] = loc_alert_en_en_la3_qs;
			end
			addr_hit[9]: begin
				reg_rdata_next[1:0] = loc_alert_class_class_la0_qs;
				reg_rdata_next[3:2] = loc_alert_class_class_la1_qs;
				reg_rdata_next[5:4] = loc_alert_class_class_la2_qs;
				reg_rdata_next[7:6] = loc_alert_class_class_la3_qs;
			end
			addr_hit[10]: begin
				reg_rdata_next[0] = loc_alert_cause_la0_qs;
				reg_rdata_next[1] = loc_alert_cause_la1_qs;
				reg_rdata_next[2] = loc_alert_cause_la2_qs;
				reg_rdata_next[3] = loc_alert_cause_la3_qs;
			end
			addr_hit[11]: begin
				reg_rdata_next[0] = classa_ctrl_en_qs;
				reg_rdata_next[1] = classa_ctrl_lock_qs;
				reg_rdata_next[2] = classa_ctrl_en_e0_qs;
				reg_rdata_next[3] = classa_ctrl_en_e1_qs;
				reg_rdata_next[4] = classa_ctrl_en_e2_qs;
				reg_rdata_next[5] = classa_ctrl_en_e3_qs;
				reg_rdata_next[7:6] = classa_ctrl_map_e0_qs;
				reg_rdata_next[9:8] = classa_ctrl_map_e1_qs;
				reg_rdata_next[11:10] = classa_ctrl_map_e2_qs;
				reg_rdata_next[13:12] = classa_ctrl_map_e3_qs;
			end
			addr_hit[12]: reg_rdata_next[0] = classa_clren_qs;
			addr_hit[13]: reg_rdata_next[0] = 1'sb0;
			addr_hit[14]: reg_rdata_next[15:0] = classa_accum_cnt_qs;
			addr_hit[15]: reg_rdata_next[15:0] = classa_accum_thresh_qs;
			addr_hit[16]: reg_rdata_next[31:0] = classa_timeout_cyc_qs;
			addr_hit[17]: reg_rdata_next[31:0] = classa_phase0_cyc_qs;
			addr_hit[18]: reg_rdata_next[31:0] = classa_phase1_cyc_qs;
			addr_hit[19]: reg_rdata_next[31:0] = classa_phase2_cyc_qs;
			addr_hit[20]: reg_rdata_next[31:0] = classa_phase3_cyc_qs;
			addr_hit[21]: reg_rdata_next[31:0] = classa_esc_cnt_qs;
			addr_hit[22]: reg_rdata_next[2:0] = classa_state_qs;
			addr_hit[23]: begin
				reg_rdata_next[0] = classb_ctrl_en_qs;
				reg_rdata_next[1] = classb_ctrl_lock_qs;
				reg_rdata_next[2] = classb_ctrl_en_e0_qs;
				reg_rdata_next[3] = classb_ctrl_en_e1_qs;
				reg_rdata_next[4] = classb_ctrl_en_e2_qs;
				reg_rdata_next[5] = classb_ctrl_en_e3_qs;
				reg_rdata_next[7:6] = classb_ctrl_map_e0_qs;
				reg_rdata_next[9:8] = classb_ctrl_map_e1_qs;
				reg_rdata_next[11:10] = classb_ctrl_map_e2_qs;
				reg_rdata_next[13:12] = classb_ctrl_map_e3_qs;
			end
			addr_hit[24]: reg_rdata_next[0] = classb_clren_qs;
			addr_hit[25]: reg_rdata_next[0] = 1'sb0;
			addr_hit[26]: reg_rdata_next[15:0] = classb_accum_cnt_qs;
			addr_hit[27]: reg_rdata_next[15:0] = classb_accum_thresh_qs;
			addr_hit[28]: reg_rdata_next[31:0] = classb_timeout_cyc_qs;
			addr_hit[29]: reg_rdata_next[31:0] = classb_phase0_cyc_qs;
			addr_hit[30]: reg_rdata_next[31:0] = classb_phase1_cyc_qs;
			addr_hit[31]: reg_rdata_next[31:0] = classb_phase2_cyc_qs;
			addr_hit[32]: reg_rdata_next[31:0] = classb_phase3_cyc_qs;
			addr_hit[33]: reg_rdata_next[31:0] = classb_esc_cnt_qs;
			addr_hit[34]: reg_rdata_next[2:0] = classb_state_qs;
			addr_hit[35]: begin
				reg_rdata_next[0] = classc_ctrl_en_qs;
				reg_rdata_next[1] = classc_ctrl_lock_qs;
				reg_rdata_next[2] = classc_ctrl_en_e0_qs;
				reg_rdata_next[3] = classc_ctrl_en_e1_qs;
				reg_rdata_next[4] = classc_ctrl_en_e2_qs;
				reg_rdata_next[5] = classc_ctrl_en_e3_qs;
				reg_rdata_next[7:6] = classc_ctrl_map_e0_qs;
				reg_rdata_next[9:8] = classc_ctrl_map_e1_qs;
				reg_rdata_next[11:10] = classc_ctrl_map_e2_qs;
				reg_rdata_next[13:12] = classc_ctrl_map_e3_qs;
			end
			addr_hit[36]: reg_rdata_next[0] = classc_clren_qs;
			addr_hit[37]: reg_rdata_next[0] = 1'sb0;
			addr_hit[38]: reg_rdata_next[15:0] = classc_accum_cnt_qs;
			addr_hit[39]: reg_rdata_next[15:0] = classc_accum_thresh_qs;
			addr_hit[40]: reg_rdata_next[31:0] = classc_timeout_cyc_qs;
			addr_hit[41]: reg_rdata_next[31:0] = classc_phase0_cyc_qs;
			addr_hit[42]: reg_rdata_next[31:0] = classc_phase1_cyc_qs;
			addr_hit[43]: reg_rdata_next[31:0] = classc_phase2_cyc_qs;
			addr_hit[44]: reg_rdata_next[31:0] = classc_phase3_cyc_qs;
			addr_hit[45]: reg_rdata_next[31:0] = classc_esc_cnt_qs;
			addr_hit[46]: reg_rdata_next[2:0] = classc_state_qs;
			addr_hit[47]: begin
				reg_rdata_next[0] = classd_ctrl_en_qs;
				reg_rdata_next[1] = classd_ctrl_lock_qs;
				reg_rdata_next[2] = classd_ctrl_en_e0_qs;
				reg_rdata_next[3] = classd_ctrl_en_e1_qs;
				reg_rdata_next[4] = classd_ctrl_en_e2_qs;
				reg_rdata_next[5] = classd_ctrl_en_e3_qs;
				reg_rdata_next[7:6] = classd_ctrl_map_e0_qs;
				reg_rdata_next[9:8] = classd_ctrl_map_e1_qs;
				reg_rdata_next[11:10] = classd_ctrl_map_e2_qs;
				reg_rdata_next[13:12] = classd_ctrl_map_e3_qs;
			end
			addr_hit[48]: reg_rdata_next[0] = classd_clren_qs;
			addr_hit[49]: reg_rdata_next[0] = 1'sb0;
			addr_hit[50]: reg_rdata_next[15:0] = classd_accum_cnt_qs;
			addr_hit[51]: reg_rdata_next[15:0] = classd_accum_thresh_qs;
			addr_hit[52]: reg_rdata_next[31:0] = classd_timeout_cyc_qs;
			addr_hit[53]: reg_rdata_next[31:0] = classd_phase0_cyc_qs;
			addr_hit[54]: reg_rdata_next[31:0] = classd_phase1_cyc_qs;
			addr_hit[55]: reg_rdata_next[31:0] = classd_phase2_cyc_qs;
			addr_hit[56]: reg_rdata_next[31:0] = classd_phase3_cyc_qs;
			addr_hit[57]: reg_rdata_next[31:0] = classd_esc_cnt_qs;
			addr_hit[58]: reg_rdata_next[2:0] = classd_state_qs;
			default: reg_rdata_next = 1'sb1;
		endcase
	end
endmodule
