module prim_esc_receiver (
	clk_i,
	rst_ni,
	esc_en_o,
	esc_rx_o,
	esc_tx_i
);
	localparam [2:0] Idle = 0;
	localparam [2:0] Check = 1;
	localparam [2:0] PingResp = 2;
	localparam [2:0] EscResp = 3;
	localparam [2:0] SigInt = 4;
	input clk_i;
	input rst_ni;
	output reg esc_en_o;
	output wire [1:0] esc_rx_o;
	input wire [1:0] esc_tx_i;
	wire esc_level;
	wire sigint_detected;
	prim_diff_decode #(.AsyncOn(1'b0)) i_decode_esc(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.diff_pi(esc_tx_i[1]),
		.diff_ni(esc_tx_i[0]),
		.level_o(esc_level),
		.rise_o(),
		.fall_o(),
		.event_o(),
		.sigint_o(sigint_detected)
	);
	reg [2:0] state_d;
	reg [2:0] state_q;
	reg resp_pd;
	reg resp_pq;
	reg resp_nd;
	reg resp_nq;
	assign esc_rx_o[1] = resp_pq;
	assign esc_rx_o[0] = resp_nq;
	always @(*) begin : p_fsm
		state_d = state_q;
		resp_pd = 1'b0;
		resp_nd = 1'b1;
		esc_en_o = 1'b0;
		case (state_q)
			Idle:
				if (esc_level) begin
					state_d = Check;
					resp_pd = 1'b1;
					resp_nd = 1'b0;
				end
			Check: begin
				state_d = PingResp;
				if (esc_level) begin
					state_d = EscResp;
					esc_en_o = 1'b1;
				end
			end
			PingResp: begin
				state_d = Idle;
				resp_pd = 1'b1;
				resp_nd = 1'b0;
				if (esc_level) begin
					state_d = EscResp;
					esc_en_o = 1'b1;
				end
			end
			EscResp: begin
				state_d = Idle;
				if (esc_level) begin
					state_d = EscResp;
					resp_pd = ~resp_pq;
					resp_nd = resp_pq;
					esc_en_o = 1'b1;
				end
			end
			SigInt: begin
				state_d = Idle;
				if (sigint_detected) begin
					state_d = SigInt;
					resp_pd = ~resp_pq;
					resp_nd = ~resp_pq;
				end
			end
			default: state_d = Idle;
		endcase
		if (sigint_detected && (state_q != SigInt)) begin
			state_d = SigInt;
			resp_pd = 1'b0;
			resp_nd = 1'b0;
		end
	end
	always @(posedge clk_i or negedge rst_ni) begin : p_regs
		if (!rst_ni) begin
			state_q <= Idle;
			resp_pq <= 1'b0;
			resp_nq <= 1'b1;
		end
		else begin
			state_q <= state_d;
			resp_pq <= resp_pd;
			resp_nq <= resp_nd;
		end
	end
endmodule
