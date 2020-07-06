module alert_handler_ping_timer (
	clk_i,
	rst_ni,
	entropy_i,
	en_i,
	alert_en_i,
	ping_timeout_cyc_i,
	wait_cyc_mask_i,
	alert_ping_en_o,
	esc_ping_en_o,
	alert_ping_ok_i,
	esc_ping_ok_i,
	alert_ping_fail_o,
	esc_ping_fail_o
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
	localparam [1:0] Init = 0;
	localparam [1:0] RespWait = 1;
	localparam [1:0] DoPing = 2;
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
	parameter MaxLenSVA = 1'b1;
	parameter LockupSVA = 1'b1;
	input clk_i;
	input rst_ni;
	input entropy_i;
	input en_i;
	input [NAlerts - 1:0] alert_en_i;
	input [PING_CNT_DW - 1:0] ping_timeout_cyc_i;
	input [PING_CNT_DW - 1:0] wait_cyc_mask_i;
	output wire [NAlerts - 1:0] alert_ping_en_o;
	output wire [N_ESC_SEV - 1:0] esc_ping_en_o;
	input [NAlerts - 1:0] alert_ping_ok_i;
	input [N_ESC_SEV - 1:0] esc_ping_ok_i;
	output reg alert_ping_fail_o;
	output reg esc_ping_fail_o;
	localparam [31:0] NModsToPing = NAlerts + N_ESC_SEV;
	localparam [31:0] IdDw = $clog2(alert_handler_reg_pkg_NAlerts + alert_handler_reg_pkg_N_ESC_SEV);
	localparam [1023:0] perm = {32'd4, 32'd11, 32'd25, 32'd3, 32'd15, 32'd16, 32'd1, 32'd10, 32'd2, 32'd22, 32'd7, 32'd0, 32'd23, 32'd28, 32'd30, 32'd19, 32'd27, 32'd12, 32'd24, 32'd26, 32'd14, 32'd21, 32'd18, 32'd5, 32'd13, 32'd8, 32'd29, 32'd31, 32'd20, 32'd6, 32'd9, 32'd17};
	reg lfsr_en;
	wire [31:0] lfsr_state;
	wire [31:0] perm_state;
	wire [(16 - IdDw) - 1:0] unused_perm_state;
	prim_lfsr #(
		.LfsrDw(32),
		.EntropyDw(1),
		.StateOutDw(32),
		.DefaultSeed(LfsrSeed),
		.MaxLenSVA(MaxLenSVA),
		.LockupSVA(LockupSVA),
		.ExtSeedSVA(1'b0)
	) i_prim_lfsr(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.seed_en_i(1'b0),
		.seed_i(1'sb0),
		.lfsr_en_i(lfsr_en),
		.entropy_i(entropy_i),
		.state_o(lfsr_state)
	);
	generate
		genvar k;
		for (k = 0; k < 32; k = k + 1) begin : gen_perm
			assign perm_state[k] = lfsr_state[perm[(31 - k) * 32+:32]];
		end
	endgenerate
	wire [IdDw - 1:0] id_to_ping;
	wire [PING_CNT_DW - 1:0] wait_cyc;
	assign id_to_ping = perm_state[16+:IdDw];
	assign unused_perm_state = perm_state[31:16 + IdDw];
	assign wait_cyc = sv2v_cast_3E03F({perm_state[15:2], 8'h01, perm_state[1:0]}) & wait_cyc_mask_i;
	reg [(2 ** IdDw) - 1:0] enable_mask;
	always @(*) begin : p_enable_mask
		enable_mask = 1'sb0;
		enable_mask[NAlerts - 1:0] = alert_en_i;
		enable_mask[NModsToPing - 1:NAlerts] = 1'sb1;
	end
	wire id_vld;
	assign id_vld = enable_mask[id_to_ping];
	wire [PING_CNT_DW - 1:0] cnt_d;
	reg [PING_CNT_DW - 1:0] cnt_q;
	reg cnt_en;
	reg cnt_clr;
	wire wait_ge;
	wire timeout_ge;
	assign cnt_d = cnt_q + 1'b1;
	assign wait_ge = cnt_q >= wait_cyc;
	assign timeout_ge = cnt_q >= ping_timeout_cyc_i;
	reg [1:0] state_d;
	reg [1:0] state_q;
	reg ping_en;
	wire ping_ok;
	wire [NModsToPing - 1:0] ping_sel;
	wire [NModsToPing - 1:0] spurious_ping;
	wire spurious_alert_ping;
	wire spurious_esc_ping;
	assign ping_sel = sv2v_cast_A4807(ping_en) << id_to_ping;
	assign alert_ping_en_o = ping_sel[NAlerts - 1:0];
	assign esc_ping_en_o = ping_sel[NModsToPing - 1:NAlerts];
	assign ping_ok = |({esc_ping_ok_i, alert_ping_ok_i} & ping_sel);
	assign spurious_ping = {esc_ping_ok_i, alert_ping_ok_i} & ~ping_sel;
	assign spurious_alert_ping = |spurious_ping[NAlerts - 1:0];
	assign spurious_esc_ping = |spurious_ping[NModsToPing - 1:NAlerts];
	always @(*) begin : p_fsm
		state_d = state_q;
		cnt_en = 1'b0;
		cnt_clr = 1'b0;
		lfsr_en = 1'b0;
		ping_en = 1'b0;
		alert_ping_fail_o = spurious_alert_ping;
		esc_ping_fail_o = spurious_esc_ping;
		case (state_q)
			Init: begin
				cnt_clr = 1'b1;
				if (en_i)
					state_d = RespWait;
			end
			RespWait:
				if (!id_vld) begin
					lfsr_en = 1'b1;
					cnt_clr = 1'b1;
				end
				else if (wait_ge) begin
					state_d = DoPing;
					cnt_clr = 1'b1;
				end
				else
					cnt_en = 1'b1;
			DoPing: begin
				cnt_en = 1'b1;
				ping_en = 1'b1;
				if (timeout_ge || ping_ok) begin
					state_d = RespWait;
					lfsr_en = 1'b1;
					cnt_clr = 1'b1;
					if (timeout_ge)
						if (id_to_ping < NAlerts)
							alert_ping_fail_o = 1'b1;
						else
							esc_ping_fail_o = 1'b1;
				end
			end
			default: begin
				alert_ping_fail_o = 1'b1;
				esc_ping_fail_o = 1'b1;
			end
		endcase
	end
	always @(posedge clk_i or negedge rst_ni) begin : p_regs
		if (!rst_ni) begin
			state_q <= Init;
			cnt_q <= 1'sb0;
		end
		else begin
			state_q <= state_d;
			if (cnt_clr)
				cnt_q <= 1'sb0;
			else if (cnt_en)
				cnt_q <= cnt_d;
		end
	end
	function automatic [alert_handler_reg_pkg_PING_CNT_DW - 1:0] sv2v_cast_3E03F;
		input reg [alert_handler_reg_pkg_PING_CNT_DW - 1:0] inp;
		sv2v_cast_3E03F = inp;
	endfunction
	function automatic [(alert_handler_reg_pkg_NAlerts + alert_handler_reg_pkg_N_ESC_SEV) - 1:0] sv2v_cast_A4807;
		input reg [(alert_handler_reg_pkg_NAlerts + alert_handler_reg_pkg_N_ESC_SEV) - 1:0] inp;
		sv2v_cast_A4807 = inp;
	endfunction
endmodule
