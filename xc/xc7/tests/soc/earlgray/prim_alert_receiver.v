module prim_alert_receiver (
	clk_i,
	rst_ni,
	ping_en_i,
	ping_ok_o,
	integ_fail_o,
	alert_o,
	alert_rx_o,
	alert_tx_i
);
	localparam [1:0] Idle = 0;
	localparam [1:0] HsAckWait = 1;
	localparam [1:0] Pause0 = 2;
	localparam [1:0] Pause1 = 3;
	parameter AsyncOn = 1'b0;
	input clk_i;
	input rst_ni;
	input ping_en_i;
	output reg ping_ok_o;
	output reg integ_fail_o;
	output reg alert_o;
	output wire [3:0] alert_rx_o;
	input wire [1:0] alert_tx_i;
	wire alert_level;
	wire alert_sigint;
	prim_diff_decode #(.AsyncOn(AsyncOn)) i_decode_alert(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.diff_pi(alert_tx_i[1]),
		.diff_ni(alert_tx_i[0]),
		.level_o(alert_level),
		.rise_o(),
		.fall_o(),
		.event_o(),
		.sigint_o(alert_sigint)
	);
	reg [1:0] state_d;
	reg [1:0] state_q;
	wire ping_rise;
	wire ping_tog_d;
	reg ping_tog_q;
	reg ack_d;
	reg ack_q;
	wire ping_en_d;
	reg ping_en_q;
	wire ping_pending_d;
	reg ping_pending_q;
	assign ping_en_d = ping_en_i;
	assign ping_rise = ping_en_i && !ping_en_q;
	assign ping_tog_d = (ping_rise ? ~ping_tog_q : ping_tog_q);
	assign ping_pending_d = ping_rise | ((~ping_ok_o & ping_en_i) & ping_pending_q);
	assign alert_rx_o[1] = ack_q;
	assign alert_rx_o[0] = ~ack_q;
	assign alert_rx_o[3] = ping_tog_q;
	assign alert_rx_o[2] = ~ping_tog_q;
	always @(*) begin : p_fsm
		state_d = state_q;
		ack_d = 1'b0;
		ping_ok_o = 1'b0;
		integ_fail_o = 1'b0;
		alert_o = 1'b0;
		case (state_q)
			Idle:
				if (alert_level) begin
					state_d = HsAckWait;
					ack_d = 1'b1;
					if (ping_pending_q)
						ping_ok_o = 1'b1;
					else
						alert_o = 1'b1;
				end
			HsAckWait:
				if (!alert_level)
					state_d = Pause0;
				else
					ack_d = 1'b1;
			Pause0: state_d = Pause1;
			Pause1: state_d = Idle;
			default:
				;
		endcase
		if (alert_sigint) begin
			state_d = Idle;
			ack_d = 1'b0;
			ping_ok_o = 1'b0;
			integ_fail_o = 1'b1;
			alert_o = 1'b0;
		end
	end
	always @(posedge clk_i or negedge rst_ni) begin : p_reg
		if (!rst_ni) begin
			state_q <= Idle;
			ack_q <= 1'b0;
			ping_tog_q <= 1'b0;
			ping_en_q <= 1'b0;
			ping_pending_q <= 1'b0;
		end
		else begin
			state_q <= state_d;
			ack_q <= ack_d;
			ping_tog_q <= ping_tog_d;
			ping_en_q <= ping_en_d;
			ping_pending_q <= ping_pending_d;
		end
	end
	generate
		
	endgenerate
endmodule
