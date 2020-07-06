module alert_handler_esc_timer (
	clk_i,
	rst_ni,
	en_i,
	clr_i,
	accum_trig_i,
	timeout_en_i,
	timeout_cyc_i,
	esc_en_i,
	esc_map_i,
	phase_cyc_i,
	esc_trig_o,
	esc_cnt_o,
	esc_sig_en_o,
	esc_state_o
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
	input en_i;
	input clr_i;
	input accum_trig_i;
	input timeout_en_i;
	input [EscCntDw - 1:0] timeout_cyc_i;
	input [N_ESC_SEV - 1:0] esc_en_i;
	input [((N_ESC_SEV - 1) >= 0 ? ((PHASE_DW - 1) >= 0 ? (N_ESC_SEV * PHASE_DW) + -1 : (N_ESC_SEV * (2 - PHASE_DW)) + ((PHASE_DW - 1) - 1)) : ((PHASE_DW - 1) >= 0 ? ((2 - N_ESC_SEV) * PHASE_DW) + (((N_ESC_SEV - 1) * PHASE_DW) - 1) : ((2 - N_ESC_SEV) * (2 - PHASE_DW)) + (((PHASE_DW - 1) + ((N_ESC_SEV - 1) * (2 - PHASE_DW))) - 1))):((N_ESC_SEV - 1) >= 0 ? ((PHASE_DW - 1) >= 0 ? 0 : PHASE_DW - 1) : ((PHASE_DW - 1) >= 0 ? (N_ESC_SEV - 1) * PHASE_DW : (PHASE_DW - 1) + ((N_ESC_SEV - 1) * (2 - PHASE_DW))))] esc_map_i;
	input [((N_PHASES - 1) >= 0 ? ((EscCntDw - 1) >= 0 ? (N_PHASES * EscCntDw) + -1 : (N_PHASES * (2 - EscCntDw)) + ((EscCntDw - 1) - 1)) : ((EscCntDw - 1) >= 0 ? ((2 - N_PHASES) * EscCntDw) + (((N_PHASES - 1) * EscCntDw) - 1) : ((2 - N_PHASES) * (2 - EscCntDw)) + (((EscCntDw - 1) + ((N_PHASES - 1) * (2 - EscCntDw))) - 1))):((N_PHASES - 1) >= 0 ? ((EscCntDw - 1) >= 0 ? 0 : EscCntDw - 1) : ((EscCntDw - 1) >= 0 ? (N_PHASES - 1) * EscCntDw : (EscCntDw - 1) + ((N_PHASES - 1) * (2 - EscCntDw))))] phase_cyc_i;
	output reg esc_trig_o;
	output wire [EscCntDw - 1:0] esc_cnt_o;
	output wire [N_ESC_SEV - 1:0] esc_sig_en_o;
	output wire [2:0] esc_state_o;
	reg [2:0] state_d;
	reg [2:0] state_q;
	reg cnt_en;
	reg cnt_clr;
	wire cnt_ge;
	wire [EscCntDw - 1:0] cnt_d;
	reg [EscCntDw - 1:0] cnt_q;
	assign cnt_d = cnt_q + 1'b1;
	assign esc_state_o = state_q;
	assign esc_cnt_o = cnt_q;
	reg [EscCntDw - 1:0] thresh;
	assign cnt_ge = cnt_q >= thresh;
	reg [N_PHASES - 1:0] phase_oh;
	always @(*) begin : p_fsm
		state_d = state_q;
		cnt_en = 1'b0;
		cnt_clr = 1'b0;
		esc_trig_o = 1'b0;
		phase_oh = 1'sb0;
		thresh = timeout_cyc_i;
		case (state_q)
			Idle: begin
				cnt_clr = 1'b1;
				if (accum_trig_i && en_i) begin
					state_d = Phase0;
					cnt_en = 1'b1;
					esc_trig_o = 1'b1;
				end
				else if ((timeout_en_i && !cnt_ge) && en_i) begin
					cnt_en = 1'b1;
					state_d = Timeout;
				end
			end
			Timeout:
				if (accum_trig_i || (cnt_ge && timeout_en_i)) begin
					state_d = Phase0;
					cnt_en = 1'b1;
					cnt_clr = 1'b1;
					esc_trig_o = 1'b1;
				end
				else if (timeout_en_i)
					cnt_en = 1'b1;
				else begin
					state_d = Idle;
					cnt_clr = 1'b1;
				end
			Phase0: begin
				cnt_en = 1'b1;
				phase_oh[0] = 1'b1;
				thresh = phase_cyc_i[((EscCntDw - 1) >= 0 ? 0 : EscCntDw - 1) + (((N_PHASES - 1) >= 0 ? 0 : N_PHASES - 1) * ((EscCntDw - 1) >= 0 ? EscCntDw : 2 - EscCntDw))+:((EscCntDw - 1) >= 0 ? EscCntDw : 2 - EscCntDw)];
				if (clr_i) begin
					state_d = Idle;
					cnt_clr = 1'b1;
					cnt_en = 1'b0;
				end
				else if (cnt_ge) begin
					state_d = Phase1;
					cnt_clr = 1'b1;
					cnt_en = 1'b1;
				end
			end
			Phase1: begin
				cnt_en = 1'b1;
				phase_oh[1] = 1'b1;
				thresh = phase_cyc_i[((EscCntDw - 1) >= 0 ? 0 : EscCntDw - 1) + (((N_PHASES - 1) >= 0 ? 1 : -1 + (N_PHASES - 1)) * ((EscCntDw - 1) >= 0 ? EscCntDw : 2 - EscCntDw))+:((EscCntDw - 1) >= 0 ? EscCntDw : 2 - EscCntDw)];
				if (clr_i) begin
					state_d = Idle;
					cnt_clr = 1'b1;
					cnt_en = 1'b0;
				end
				else if (cnt_ge) begin
					state_d = Phase2;
					cnt_clr = 1'b1;
					cnt_en = 1'b1;
				end
			end
			Phase2: begin
				cnt_en = 1'b1;
				phase_oh[2] = 1'b1;
				thresh = phase_cyc_i[((EscCntDw - 1) >= 0 ? 0 : EscCntDw - 1) + (((N_PHASES - 1) >= 0 ? 2 : -2 + (N_PHASES - 1)) * ((EscCntDw - 1) >= 0 ? EscCntDw : 2 - EscCntDw))+:((EscCntDw - 1) >= 0 ? EscCntDw : 2 - EscCntDw)];
				if (clr_i) begin
					state_d = Idle;
					cnt_clr = 1'b1;
					cnt_en = 1'b0;
				end
				else if (cnt_ge) begin
					state_d = Phase3;
					cnt_clr = 1'b1;
				end
			end
			Phase3: begin
				cnt_en = 1'b1;
				phase_oh[3] = 1'b1;
				thresh = phase_cyc_i[((EscCntDw - 1) >= 0 ? 0 : EscCntDw - 1) + (((N_PHASES - 1) >= 0 ? 3 : -3 + (N_PHASES - 1)) * ((EscCntDw - 1) >= 0 ? EscCntDw : 2 - EscCntDw))+:((EscCntDw - 1) >= 0 ? EscCntDw : 2 - EscCntDw)];
				if (clr_i) begin
					state_d = Idle;
					cnt_clr = 1'b1;
					cnt_en = 1'b0;
				end
				else if (cnt_ge) begin
					state_d = Terminal;
					cnt_clr = 1'b1;
				end
			end
			Terminal: begin
				cnt_clr = 1'b1;
				if (clr_i)
					state_d = Idle;
			end
			default: state_d = Idle;
		endcase
	end
	wire [((N_ESC_SEV - 1) >= 0 ? ((N_PHASES - 1) >= 0 ? (N_ESC_SEV * N_PHASES) + -1 : (N_ESC_SEV * (2 - N_PHASES)) + ((N_PHASES - 1) - 1)) : ((N_PHASES - 1) >= 0 ? ((2 - N_ESC_SEV) * N_PHASES) + (((N_ESC_SEV - 1) * N_PHASES) - 1) : ((2 - N_ESC_SEV) * (2 - N_PHASES)) + (((N_PHASES - 1) + ((N_ESC_SEV - 1) * (2 - N_PHASES))) - 1))):((N_ESC_SEV - 1) >= 0 ? ((N_PHASES - 1) >= 0 ? 0 : N_PHASES - 1) : ((N_PHASES - 1) >= 0 ? (N_ESC_SEV - 1) * N_PHASES : (N_PHASES - 1) + ((N_ESC_SEV - 1) * (2 - N_PHASES))))] esc_map_oh;
	generate
		genvar k;
		for (k = 0; k < N_ESC_SEV; k = k + 1) begin : gen_phase_map
			assign esc_map_oh[((N_PHASES - 1) >= 0 ? 0 : N_PHASES - 1) + (((N_ESC_SEV - 1) >= 0 ? k : 0 - (k - (N_ESC_SEV - 1))) * ((N_PHASES - 1) >= 0 ? N_PHASES : 2 - N_PHASES))+:((N_PHASES - 1) >= 0 ? N_PHASES : 2 - N_PHASES)] = sv2v_cast_8DDE3(esc_en_i[k]) << esc_map_i[((PHASE_DW - 1) >= 0 ? 0 : PHASE_DW - 1) + (((N_ESC_SEV - 1) >= 0 ? k : 0 - (k - (N_ESC_SEV - 1))) * ((PHASE_DW - 1) >= 0 ? PHASE_DW : 2 - PHASE_DW))+:((PHASE_DW - 1) >= 0 ? PHASE_DW : 2 - PHASE_DW)];
			assign esc_sig_en_o[k] = |(esc_map_oh[((N_PHASES - 1) >= 0 ? 0 : N_PHASES - 1) + (((N_ESC_SEV - 1) >= 0 ? k : 0 - (k - (N_ESC_SEV - 1))) * ((N_PHASES - 1) >= 0 ? N_PHASES : 2 - N_PHASES))+:((N_PHASES - 1) >= 0 ? N_PHASES : 2 - N_PHASES)] & phase_oh);
		end
	endgenerate
	always @(posedge clk_i or negedge rst_ni) begin : p_regs
		if (!rst_ni) begin
			state_q <= Idle;
			cnt_q <= 1'sb0;
		end
		else begin
			state_q <= state_d;
			if (cnt_en && cnt_clr)
				cnt_q <= sv2v_cast_D5A5F(1'b1);
			else if (cnt_clr)
				cnt_q <= 1'sb0;
			else if (cnt_en)
				cnt_q <= cnt_d;
		end
	end
	function automatic [alert_handler_reg_pkg_N_ESC_SEV - 1:0] sv2v_cast_8DDE3;
		input reg [alert_handler_reg_pkg_N_ESC_SEV - 1:0] inp;
		sv2v_cast_8DDE3 = inp;
	endfunction
	function automatic [alert_handler_reg_pkg_EscCntDw - 1:0] sv2v_cast_D5A5F;
		input reg [alert_handler_reg_pkg_EscCntDw - 1:0] inp;
		sv2v_cast_D5A5F = inp;
	endfunction
endmodule
