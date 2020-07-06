module prim_alert_sender (
	clk_i,
	rst_ni,
	alert_i,
	alert_rx_i,
	alert_tx_o
);
	localparam [2:0] Idle = 0;
	localparam [2:0] HsPhase1 = 1;
	localparam [2:0] HsPhase2 = 2;
	localparam [2:0] SigInt = 3;
	localparam [2:0] Pause0 = 4;
	localparam [2:0] Pause1 = 5;
	parameter AsyncOn = 1'b1;
	input clk_i;
	input rst_ni;
	input alert_i;
	input wire [3:0] alert_rx_i;
	output wire [1:0] alert_tx_o;
	wire ping_sigint;
	wire ping_event;
	prim_diff_decode #(.AsyncOn(AsyncOn)) i_decode_ping(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.diff_pi(alert_rx_i[3]),
		.diff_ni(alert_rx_i[2]),
		.level_o(),
		.rise_o(),
		.fall_o(),
		.event_o(ping_event),
		.sigint_o(ping_sigint)
	);
	wire ack_sigint;
	wire ack_level;
	prim_diff_decode #(.AsyncOn(AsyncOn)) i_decode_ack(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.diff_pi(alert_rx_i[1]),
		.diff_ni(alert_rx_i[0]),
		.level_o(ack_level),
		.rise_o(),
		.fall_o(),
		.event_o(),
		.sigint_o(ack_sigint)
	);
	reg [2:0] state_d;
	reg [2:0] state_q;
	reg alert_pq;
	reg alert_nq;
	reg alert_pd;
	reg alert_nd;
	wire sigint_detected;
	assign sigint_detected = ack_sigint | ping_sigint;
	assign alert_tx_o[1] = alert_pq;
	assign alert_tx_o[0] = alert_nq;
	wire alert_set_d;
	reg alert_set_q;
	reg alert_clr;
	wire ping_set_d;
	reg ping_set_q;
	reg ping_clr;
	assign alert_set_d = (alert_clr ? 1'b0 : alert_set_q | alert_i);
	assign ping_set_d = (ping_clr ? 1'b0 : ping_set_q | ping_event);
	always @(*) begin : p_fsm
		state_d = state_q;
		alert_pd = 1'b0;
		alert_nd = 1'b1;
		ping_clr = 1'b0;
		alert_clr = 1'b0;
		case (state_q)
			Idle:
				if (((alert_i || alert_set_q) || ping_event) || ping_set_q) begin
					state_d = HsPhase1;
					alert_pd = 1'b1;
					alert_nd = 1'b0;
					if (ping_event || ping_set_q)
						ping_clr = 1'b1;
					else
						alert_clr = 1'b1;
				end
			HsPhase1:
				if (ack_level)
					state_d = HsPhase2;
				else begin
					alert_pd = 1'b1;
					alert_nd = 1'b0;
				end
			HsPhase2:
				if (!ack_level)
					state_d = Pause0;
			Pause0: state_d = Pause1;
			Pause1: state_d = Idle;
			SigInt: begin
				state_d = Idle;
				if (sigint_detected) begin
					state_d = SigInt;
					alert_pd = ~alert_pq;
					alert_nd = ~alert_pq;
				end
			end
			default: state_d = Idle;
		endcase
		if (sigint_detected && (state_q != SigInt)) begin
			state_d = SigInt;
			alert_pd = 1'b0;
			alert_nd = 1'b0;
			ping_clr = 1'b0;
			alert_clr = 1'b0;
		end
	end
	always @(posedge clk_i or negedge rst_ni) begin : p_reg
		if (!rst_ni) begin
			state_q <= Idle;
			alert_pq <= 1'b0;
			alert_nq <= 1'b1;
			alert_set_q <= 1'b0;
			ping_set_q <= 1'b0;
		end
		else begin
			state_q <= state_d;
			alert_pq <= alert_pd;
			alert_nq <= alert_nd;
			alert_set_q <= alert_set_d;
			ping_set_q <= ping_set_d;
		end
	end
	generate
		
	endgenerate
endmodule
