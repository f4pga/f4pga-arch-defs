module alert_handler_class (
	alert_trig_i,
	loc_alert_trig_i,
	alert_en_i,
	loc_alert_en_i,
	alert_class_i,
	loc_alert_class_i,
	alert_cause_o,
	loc_alert_cause_o,
	class_trig_o
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
	input [NAlerts - 1:0] alert_trig_i;
	input [N_LOC_ALERT - 1:0] loc_alert_trig_i;
	input [NAlerts - 1:0] alert_en_i;
	input [N_LOC_ALERT - 1:0] loc_alert_en_i;
	input [((NAlerts - 1) >= 0 ? ((CLASS_DW - 1) >= 0 ? (NAlerts * CLASS_DW) + -1 : (NAlerts * (2 - CLASS_DW)) + ((CLASS_DW - 1) - 1)) : ((CLASS_DW - 1) >= 0 ? ((2 - NAlerts) * CLASS_DW) + (((NAlerts - 1) * CLASS_DW) - 1) : ((2 - NAlerts) * (2 - CLASS_DW)) + (((CLASS_DW - 1) + ((NAlerts - 1) * (2 - CLASS_DW))) - 1))):((NAlerts - 1) >= 0 ? ((CLASS_DW - 1) >= 0 ? 0 : CLASS_DW - 1) : ((CLASS_DW - 1) >= 0 ? (NAlerts - 1) * CLASS_DW : (CLASS_DW - 1) + ((NAlerts - 1) * (2 - CLASS_DW))))] alert_class_i;
	input [((N_LOC_ALERT - 1) >= 0 ? ((CLASS_DW - 1) >= 0 ? (N_LOC_ALERT * CLASS_DW) + -1 : (N_LOC_ALERT * (2 - CLASS_DW)) + ((CLASS_DW - 1) - 1)) : ((CLASS_DW - 1) >= 0 ? ((2 - N_LOC_ALERT) * CLASS_DW) + (((N_LOC_ALERT - 1) * CLASS_DW) - 1) : ((2 - N_LOC_ALERT) * (2 - CLASS_DW)) + (((CLASS_DW - 1) + ((N_LOC_ALERT - 1) * (2 - CLASS_DW))) - 1))):((N_LOC_ALERT - 1) >= 0 ? ((CLASS_DW - 1) >= 0 ? 0 : CLASS_DW - 1) : ((CLASS_DW - 1) >= 0 ? (N_LOC_ALERT - 1) * CLASS_DW : (CLASS_DW - 1) + ((N_LOC_ALERT - 1) * (2 - CLASS_DW))))] loc_alert_class_i;
	output wire [NAlerts - 1:0] alert_cause_o;
	output wire [N_LOC_ALERT - 1:0] loc_alert_cause_o;
	output wire [N_CLASSES - 1:0] class_trig_o;
	assign alert_cause_o = alert_en_i & alert_trig_i;
	assign loc_alert_cause_o = loc_alert_en_i & loc_alert_trig_i;
	reg [((N_CLASSES - 1) >= 0 ? ((NAlerts - 1) >= 0 ? (N_CLASSES * NAlerts) + -1 : (N_CLASSES * (2 - NAlerts)) + ((NAlerts - 1) - 1)) : ((NAlerts - 1) >= 0 ? ((2 - N_CLASSES) * NAlerts) + (((N_CLASSES - 1) * NAlerts) - 1) : ((2 - N_CLASSES) * (2 - NAlerts)) + (((NAlerts - 1) + ((N_CLASSES - 1) * (2 - NAlerts))) - 1))):((N_CLASSES - 1) >= 0 ? ((NAlerts - 1) >= 0 ? 0 : NAlerts - 1) : ((NAlerts - 1) >= 0 ? (N_CLASSES - 1) * NAlerts : (NAlerts - 1) + ((N_CLASSES - 1) * (2 - NAlerts))))] class_masks;
	reg [((N_CLASSES - 1) >= 0 ? ((N_LOC_ALERT - 1) >= 0 ? (N_CLASSES * N_LOC_ALERT) + -1 : (N_CLASSES * (2 - N_LOC_ALERT)) + ((N_LOC_ALERT - 1) - 1)) : ((N_LOC_ALERT - 1) >= 0 ? ((2 - N_CLASSES) * N_LOC_ALERT) + (((N_CLASSES - 1) * N_LOC_ALERT) - 1) : ((2 - N_CLASSES) * (2 - N_LOC_ALERT)) + (((N_LOC_ALERT - 1) + ((N_CLASSES - 1) * (2 - N_LOC_ALERT))) - 1))):((N_CLASSES - 1) >= 0 ? ((N_LOC_ALERT - 1) >= 0 ? 0 : N_LOC_ALERT - 1) : ((N_LOC_ALERT - 1) >= 0 ? (N_CLASSES - 1) * N_LOC_ALERT : (N_LOC_ALERT - 1) + ((N_CLASSES - 1) * (2 - N_LOC_ALERT))))] loc_class_masks;
	always @(*) begin : p_class_mask
		class_masks = 1'sb0;
		loc_class_masks = 1'sb0;
		begin : sv2v_autoblock_147
			reg [31:0] kk;
			for (kk = 0; kk < NAlerts; kk = kk + 1)
				class_masks[(((N_CLASSES - 1) >= 0 ? alert_class_i[((CLASS_DW - 1) >= 0 ? 0 : CLASS_DW - 1) + (((NAlerts - 1) >= 0 ? kk : 0 - (kk - (NAlerts - 1))) * ((CLASS_DW - 1) >= 0 ? CLASS_DW : 2 - CLASS_DW))+:((CLASS_DW - 1) >= 0 ? CLASS_DW : 2 - CLASS_DW)] : 0 - (alert_class_i[((CLASS_DW - 1) >= 0 ? 0 : CLASS_DW - 1) + (((NAlerts - 1) >= 0 ? kk : 0 - (kk - (NAlerts - 1))) * ((CLASS_DW - 1) >= 0 ? CLASS_DW : 2 - CLASS_DW))+:((CLASS_DW - 1) >= 0 ? CLASS_DW : 2 - CLASS_DW)] - (N_CLASSES - 1))) * ((NAlerts - 1) >= 0 ? NAlerts : 2 - NAlerts)) + ((NAlerts - 1) >= 0 ? kk : 0 - (kk - (NAlerts - 1)))] = 1'b1;
		end
		begin : sv2v_autoblock_148
			reg [31:0] kk;
			for (kk = 0; kk < N_LOC_ALERT; kk = kk + 1)
				loc_class_masks[(((N_CLASSES - 1) >= 0 ? loc_alert_class_i[((CLASS_DW - 1) >= 0 ? 0 : CLASS_DW - 1) + (((N_LOC_ALERT - 1) >= 0 ? kk : 0 - (kk - (N_LOC_ALERT - 1))) * ((CLASS_DW - 1) >= 0 ? CLASS_DW : 2 - CLASS_DW))+:((CLASS_DW - 1) >= 0 ? CLASS_DW : 2 - CLASS_DW)] : 0 - (loc_alert_class_i[((CLASS_DW - 1) >= 0 ? 0 : CLASS_DW - 1) + (((N_LOC_ALERT - 1) >= 0 ? kk : 0 - (kk - (N_LOC_ALERT - 1))) * ((CLASS_DW - 1) >= 0 ? CLASS_DW : 2 - CLASS_DW))+:((CLASS_DW - 1) >= 0 ? CLASS_DW : 2 - CLASS_DW)] - (N_CLASSES - 1))) * ((N_LOC_ALERT - 1) >= 0 ? N_LOC_ALERT : 2 - N_LOC_ALERT)) + ((N_LOC_ALERT - 1) >= 0 ? kk : 0 - (kk - (N_LOC_ALERT - 1)))] = 1'b1;
		end
	end
	generate
		genvar k;
		for (k = 0; k < N_CLASSES; k = k + 1) begin : gen_classifier
			assign class_trig_o[k] = |{alert_cause_o & class_masks[((NAlerts - 1) >= 0 ? 0 : NAlerts - 1) + (((N_CLASSES - 1) >= 0 ? k : 0 - (k - (N_CLASSES - 1))) * ((NAlerts - 1) >= 0 ? NAlerts : 2 - NAlerts))+:((NAlerts - 1) >= 0 ? NAlerts : 2 - NAlerts)], loc_alert_cause_o & loc_class_masks[((N_LOC_ALERT - 1) >= 0 ? 0 : N_LOC_ALERT - 1) + (((N_CLASSES - 1) >= 0 ? k : 0 - (k - (N_CLASSES - 1))) * ((N_LOC_ALERT - 1) >= 0 ? N_LOC_ALERT : 2 - N_LOC_ALERT))+:((N_LOC_ALERT - 1) >= 0 ? N_LOC_ALERT : 2 - N_LOC_ALERT)]};
		end
	endgenerate
endmodule
