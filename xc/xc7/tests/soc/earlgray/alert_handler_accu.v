module alert_handler_accu (
	clk_i,
	rst_ni,
	class_en_i,
	clr_i,
	class_trig_i,
	thresh_i,
	accu_cnt_o,
	accu_trig_o
);
	parameter signed [31:0] alert_handler_reg_pkg_AccuCntDw = 16;
	parameter [alert_handler_reg_pkg_NAlerts - 1:0] alert_handler_reg_pkg_AsyncOn = 1'b0;
	parameter signed [31:0] alert_handler_reg_pkg_CLASS_DW = 2;
	parameter signed [31:0] alert_handler_reg_pkg_EscCntDw = 32;
	parameter signed [31:0] alert_handler_reg_pkg_LfsrSeed = 2147483647;
	parameter signed [31:0] alert_handler_reg_pkg_NAlerts = 1;
	parameter signed [31:0] alert_handler_reg_pkg_N_CLASSES = 4;
	parameter signed [31:0] alert_handler_reg_pkg_N_ESC_SEV = 4;
	parameter signed [31:0] alert_handler_reg_pkg_N_LOC_ALERT = 4;
	parameter signed [31:0] alert_handler_reg_pkg_N_PHASES = 4;
	parameter signed [31:0] alert_handler_reg_pkg_PHASE_DW = 2;
	parameter signed [31:0] alert_handler_reg_pkg_PING_CNT_DW = 24;
	localparam [31:0] NAlerts = alert_handler_reg_pkg_NAlerts;
	localparam [31:0] EscCntDw = alert_handler_reg_pkg_EscCntDw;
	localparam [31:0] AccuCntDw = alert_handler_reg_pkg_AccuCntDw;
	localparam [31:0] LfsrSeed = alert_handler_reg_pkg_LfsrSeed;
	localparam [NAlerts - 1:0] AsyncOn = alert_handler_reg_pkg_AsyncOn;
	localparam [31:0] N_CLASSES = alert_handler_reg_pkg_N_CLASSES;
	localparam [31:0] N_ESC_SEV = alert_handler_reg_pkg_N_ESC_SEV;
	localparam [31:0] N_PHASES = alert_handler_reg_pkg_N_PHASES;
	localparam [31:0] N_LOC_ALERT = alert_handler_reg_pkg_N_LOC_ALERT;
	localparam [31:0] PING_CNT_DW = alert_handler_reg_pkg_PING_CNT_DW;
	localparam [31:0] PHASE_DW = alert_handler_reg_pkg_PHASE_DW;
	localparam [31:0] CLASS_DW = alert_handler_reg_pkg_CLASS_DW;
	localparam [2:0] Idle = 3'b000;
	localparam [2:0] Timeout = 3'b001;
	localparam [2:0] Terminal = 3'b011;
	localparam [2:0] Phase0 = 3'b100;
	localparam [2:0] Phase1 = 3'b101;
	localparam [2:0] Phase2 = 3'b110;
	localparam [2:0] Phase3 = 3'b111;
	input clk_i;
	input rst_ni;
	input class_en_i;
	input clr_i;
	input class_trig_i;
	input [AccuCntDw - 1:0] thresh_i;
	output wire [AccuCntDw - 1:0] accu_cnt_o;
	output wire accu_trig_o;
	wire trig_gated;
	wire [AccuCntDw - 1:0] accu_d;
	reg [AccuCntDw - 1:0] accu_q;
	assign trig_gated = class_trig_i & class_en_i;
	assign accu_d = (clr_i ? 1'sb0 : (trig_gated && !(&accu_q) ? accu_q + 1'b1 : accu_q));
	assign accu_trig_o = (accu_q >= thresh_i) & trig_gated;
	assign accu_cnt_o = accu_q;
	always @(posedge clk_i or negedge rst_ni) begin : p_regs
		if (!rst_ni)
			accu_q <= 1'sb0;
		else
			accu_q <= accu_d;
	end
endmodule
