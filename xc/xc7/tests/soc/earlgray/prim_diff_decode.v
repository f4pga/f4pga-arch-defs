module prim_diff_decode (
	clk_i,
	rst_ni,
	diff_pi,
	diff_ni,
	level_o,
	rise_o,
	fall_o,
	event_o,
	sigint_o
);
	localparam [1:0] IsStd = 0;
	localparam [1:0] IsSkewed = 1;
	localparam [1:0] SigInt = 2;
	parameter AsyncOn = 1'b0;
	input clk_i;
	input rst_ni;
	input diff_pi;
	input diff_ni;
	output wire level_o;
	output reg rise_o;
	output reg fall_o;
	output wire event_o;
	output reg sigint_o;
	reg level_d;
	reg level_q;
	generate
		if (AsyncOn) begin : gen_async
			reg [1:0] state_d;
			reg [1:0] state_q;
			wire diff_p_edge;
			wire diff_n_edge;
			wire diff_check_ok;
			wire level;
			reg diff_pq;
			reg diff_nq;
			wire diff_pd;
			wire diff_nd;
			prim_flop_2sync #(
				.Width(1),
				.ResetValue(0)
			) i_sync_p(
				.clk_i(clk_i),
				.rst_ni(rst_ni),
				.d(diff_pi),
				.q(diff_pd)
			);
			prim_flop_2sync #(
				.Width(1),
				.ResetValue(1)
			) i_sync_n(
				.clk_i(clk_i),
				.rst_ni(rst_ni),
				.d(diff_ni),
				.q(diff_nd)
			);
			assign diff_p_edge = diff_pq ^ diff_pd;
			assign diff_n_edge = diff_nq ^ diff_nd;
			assign diff_check_ok = diff_pd ^ diff_nd;
			assign level = diff_pd;
			assign level_o = level_d;
			assign event_o = rise_o | fall_o;
			always @(*) begin : p_diff_fsm
				state_d = state_q;
				level_d = level_q;
				rise_o = 1'b0;
				fall_o = 1'b0;
				sigint_o = 1'b0;
				case (state_q)
					IsStd:
						if (diff_check_ok) begin
							level_d = level;
							if (diff_p_edge && diff_n_edge)
								if (level)
									rise_o = 1'b1;
								else
									fall_o = 1'b1;
						end
						else if (diff_p_edge || diff_n_edge)
							state_d = IsSkewed;
						else begin
							state_d = SigInt;
							sigint_o = 1'b1;
						end
					IsSkewed:
						if (diff_check_ok) begin
							state_d = IsStd;
							level_d = level;
							if (level)
								rise_o = 1'b1;
							else
								fall_o = 1'b1;
						end
						else begin
							state_d = SigInt;
							sigint_o = 1'b1;
						end
					SigInt: begin
						sigint_o = 1'b1;
						if (diff_check_ok) begin
							state_d = IsStd;
							sigint_o = 1'b0;
						end
					end
					default:
						;
				endcase
			end
			always @(posedge clk_i or negedge rst_ni) begin : p_sync_reg
				if (!rst_ni) begin
					state_q <= IsStd;
					diff_pq <= 1'b0;
					diff_nq <= 1'b1;
					level_q <= 1'b0;
				end
				else begin
					state_q <= state_d;
					diff_pq <= diff_pd;
					diff_nq <= diff_nd;
					level_q <= level_d;
				end
			end
		end
		else begin : gen_no_async
			reg diff_pq;
			wire diff_pd;
			assign diff_pd = diff_pi;
			always @(*) sigint_o = ~(diff_pi ^ diff_ni);
			assign level_o = (sigint_o ? level_q : diff_pi);
			always @(*) level_d = level_o;
			always @(*) rise_o = (~diff_pq & diff_pi) & ~sigint_o;
			always @(*) fall_o = (diff_pq & ~diff_pi) & ~sigint_o;
			assign event_o = rise_o | fall_o;
			always @(posedge clk_i or negedge rst_ni) begin : p_edge_reg
				if (!rst_ni) begin
					diff_pq <= 1'b0;
					level_q <= 1'b0;
				end
				else begin
					diff_pq <= diff_pd;
					level_q <= level_d;
				end
			end
		end
	endgenerate
	generate
		
	endgenerate
endmodule
