module prim_esc_sender (
	clk_i,
	rst_ni,
	ping_en_i,
	ping_ok_o,
	integ_fail_o,
	esc_en_i,
	esc_rx_i,
	esc_tx_o
);
	localparam [2:0] Idle = 0;
	localparam [2:0] CheckEscRespLo = 1;
	localparam [2:0] CheckEscRespHi = 2;
	localparam [2:0] CheckPingResp0 = 3;
	localparam [2:0] CheckPingResp1 = 4;
	localparam [2:0] CheckPingResp2 = 5;
	localparam [2:0] CheckPingResp3 = 6;
	input clk_i;
	input rst_ni;
	input ping_en_i;
	output reg ping_ok_o;
	output reg integ_fail_o;
	input esc_en_i;
	input wire [1:0] esc_rx_i;
	output wire [1:0] esc_tx_o;
	wire resp;
	wire sigint_detected;
	prim_diff_decode #(.AsyncOn(1'b0)) i_decode_resp(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.diff_pi(esc_rx_i[1]),
		.diff_ni(esc_rx_i[0]),
		.level_o(resp),
		.rise_o(),
		.fall_o(),
		.event_o(),
		.sigint_o(sigint_detected)
	);
	wire ping_en_d;
	reg ping_en_q;
	wire esc_en_d;
	reg esc_en_q;
	reg esc_en_q1;
	assign ping_en_d = ping_en_i;
	assign esc_en_d = esc_en_i;
	assign esc_tx_o[1] = (esc_en_i | esc_en_q) | (ping_en_d & ~ping_en_q);
	assign esc_tx_o[0] = ~esc_tx_o[1];
	reg [2:0] state_d;
	reg [2:0] state_q;
	always @(*) begin : p_fsm
		state_d = state_q;
		ping_ok_o = 1'b0;
		integ_fail_o = sigint_detected;
		case (state_q)
			Idle: begin
				if (esc_en_i)
					state_d = CheckEscRespHi;
				else if (ping_en_i)
					state_d = CheckPingResp0;
				if (resp)
					integ_fail_o = 1'b1;
			end
			CheckEscRespLo: begin
				state_d = CheckEscRespHi;
				if (!esc_tx_o[1] || resp) begin
					state_d = Idle;
					integ_fail_o = sigint_detected | resp;
				end
			end
			CheckEscRespHi: begin
				state_d = CheckEscRespLo;
				if (!esc_tx_o[1] || !resp) begin
					state_d = Idle;
					integ_fail_o = sigint_detected | ~resp;
				end
			end
			CheckPingResp0: begin
				state_d = CheckPingResp1;
				if (esc_en_i)
					state_d = CheckEscRespLo;
				else if (!resp) begin
					state_d = Idle;
					integ_fail_o = 1'b1;
				end
			end
			CheckPingResp1: begin
				state_d = CheckPingResp2;
				if (esc_en_i)
					state_d = CheckEscRespHi;
				else if (resp) begin
					state_d = Idle;
					integ_fail_o = 1'b1;
				end
			end
			CheckPingResp2: begin
				state_d = CheckPingResp3;
				if (esc_en_i)
					state_d = CheckEscRespLo;
				else if (!resp) begin
					state_d = Idle;
					integ_fail_o = 1'b1;
				end
			end
			CheckPingResp3: begin
				state_d = Idle;
				if (esc_en_i)
					state_d = CheckEscRespHi;
				else if (resp)
					integ_fail_o = 1'b1;
				else
					ping_ok_o = ping_en_i;
			end
			default: state_d = Idle;
		endcase
		if (((esc_en_i || esc_en_q) || esc_en_q1) && ping_en_i)
			ping_ok_o = 1'b1;
		if (sigint_detected) begin
			ping_ok_o = 1'b0;
			state_d = Idle;
		end
	end
	always @(posedge clk_i or negedge rst_ni) begin : p_regs
		if (!rst_ni) begin
			state_q <= Idle;
			esc_en_q <= 1'b0;
			esc_en_q1 <= 1'b0;
			ping_en_q <= 1'b0;
		end
		else begin
			state_q <= state_d;
			esc_en_q <= esc_en_d;
			esc_en_q1 <= esc_en_q;
			ping_en_q <= ping_en_d;
		end
	end
endmodule
