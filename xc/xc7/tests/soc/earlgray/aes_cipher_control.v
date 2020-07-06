module aes_cipher_control (
	clk_i,
	rst_ni,
	in_valid_i,
	in_ready_o,
	out_valid_o,
	out_ready_i,
	op_i,
	key_len_i,
	start_i,
	dec_key_gen_i,
	dec_key_gen_o,
	key_clear_i,
	key_clear_o,
	data_out_clear_i,
	data_out_clear_o,
	state_sel_o,
	state_we_o,
	add_rk_sel_o,
	key_expand_op_o,
	key_full_sel_o,
	key_full_we_o,
	key_dec_sel_o,
	key_dec_we_o,
	key_expand_step_o,
	key_expand_clear_o,
	key_expand_round_o,
	key_words_sel_o,
	round_key_sel_o
);
	localparam [2:0] IDLE = 0;
	localparam [2:0] INIT = 1;
	localparam [2:0] ROUND = 2;
	localparam [2:0] FINISH = 3;
	localparam [2:0] CLEAR = 4;
	input wire clk_i;
	input wire rst_ni;
	input wire in_valid_i;
	output reg in_ready_o;
	output reg out_valid_o;
	input wire out_ready_i;
	input wire [0:0] op_i;
	input wire [2:0] key_len_i;
	input wire start_i;
	input wire dec_key_gen_i;
	output wire dec_key_gen_o;
	input wire key_clear_i;
	output wire key_clear_o;
	input wire data_out_clear_i;
	output wire data_out_clear_o;
	output reg [1:0] state_sel_o;
	output reg state_we_o;
	output reg [1:0] add_rk_sel_o;
	output wire [0:0] key_expand_op_o;
	output reg [1:0] key_full_sel_o;
	output reg key_full_we_o;
	output reg [0:0] key_dec_sel_o;
	output reg key_dec_we_o;
	output reg key_expand_step_o;
	output reg key_expand_clear_o;
	output wire [3:0] key_expand_round_o;
	output reg [1:0] key_words_sel_o;
	output reg [0:0] round_key_sel_o;
	function automatic [7:0] aes_mul2;
		input reg [7:0] in;
		begin
			aes_mul2[7] = in[6];
			aes_mul2[6] = in[5];
			aes_mul2[5] = in[4];
			aes_mul2[4] = in[3] ^ in[7];
			aes_mul2[3] = in[2] ^ in[7];
			aes_mul2[2] = in[1];
			aes_mul2[1] = in[0] ^ in[7];
			aes_mul2[0] = in[7];
		end
	endfunction
	function automatic [7:0] aes_mul4;
		input reg [7:0] in;
		aes_mul4 = aes_mul2(aes_mul2(in));
	endfunction
	function automatic [7:0] aes_div2;
		input reg [7:0] in;
		begin
			aes_div2[7] = in[0];
			aes_div2[6] = in[7];
			aes_div2[5] = in[6];
			aes_div2[4] = in[5];
			aes_div2[3] = in[4] ^ in[0];
			aes_div2[2] = in[3] ^ in[0];
			aes_div2[1] = in[2];
			aes_div2[0] = in[1] ^ in[0];
		end
	endfunction
	function automatic [31:0] aes_circ_byte_shift;
		input reg [31:0] in;
		input integer shift;
		integer s;
		begin
			s = shift % 4;
			aes_circ_byte_shift = {in[8 * ((7 - s) % 4)+:8], in[8 * ((6 - s) % 4)+:8], in[8 * ((5 - s) % 4)+:8], in[8 * ((4 - s) % 4)+:8]};
		end
	endfunction
	function automatic [127:0] aes_transpose;
		input reg [127:0] in;
		reg [127:0] transpose;
		begin
			transpose = 1'sb0;
			begin : sv2v_autoblock_148
				reg signed [31:0] j;
				for (j = 0; j < 4; j = j + 1)
					begin : sv2v_autoblock_149
						reg signed [31:0] i;
						for (i = 0; i < 4; i = i + 1)
							transpose[((i * 4) + j) * 8+:8] = in[((j * 4) + i) * 8+:8];
					end
			end
			aes_transpose = transpose;
		end
	endfunction
	function automatic [31:0] aes_col_get;
		input reg [127:0] in;
		input reg signed [31:0] idx;
		begin : sv2v_autoblock_150
			reg signed [31:0] i;
			for (i = 0; i < 4; i = i + 1)
				aes_col_get[i * 8+:8] = in[((i * 4) + idx) * 8+:8];
		end
	endfunction
	function automatic [7:0] aes_mvm;
		input reg [7:0] vec_b;
		input reg [63:0] mat_a;
		reg [7:0] vec_c;
		begin
			vec_c = 1'sb0;
			begin : sv2v_autoblock_151
				reg signed [31:0] i;
				for (i = 0; i < 8; i = i + 1)
					begin : sv2v_autoblock_152
						reg signed [31:0] j;
						for (j = 0; j < 8; j = j + 1)
							vec_c[i] = vec_c[i] ^ (mat_a[((7 - j) * 8) + i] & vec_b[7 - j]);
					end
			end
			aes_mvm = vec_c;
		end
	endfunction
	localparam [0:0] KEY_DEC_EXPAND = 0;
	localparam [0:0] KEY_INIT_INPUT = 0;
	localparam [0:0] ROUND_KEY_DIRECT = 0;
	localparam [1:0] ADD_RK_INIT = 0;
	localparam [1:0] KEY_FULL_ENC_INIT = 0;
	localparam [1:0] KEY_WORDS_0123 = 0;
	localparam [1:0] STATE_INIT = 0;
	localparam [0:0] KEY_DEC_CLEAR = 1;
	localparam [0:0] KEY_INIT_CLEAR = 1;
	localparam [0:0] ROUND_KEY_MIXED = 1;
	localparam [1:0] ADD_RK_ROUND = 1;
	localparam [1:0] KEY_FULL_DEC_INIT = 1;
	localparam [1:0] KEY_WORDS_2345 = 1;
	localparam [1:0] STATE_ROUND = 1;
	localparam [0:0] AES_ENC = 1'b0;
	localparam [0:0] CIPH_FWD = 1'b0;
	localparam [0:0] AES_DEC = 1'b1;
	localparam [0:0] CIPH_INV = 1'b1;
	localparam [1:0] ADD_RK_FINAL = 2;
	localparam [1:0] KEY_FULL_ROUND = 2;
	localparam [1:0] KEY_WORDS_4567 = 2;
	localparam [1:0] STATE_CLEAR = 2;
	localparam [1:0] KEY_FULL_CLEAR = 3;
	localparam [1:0] KEY_WORDS_ZERO = 3;
	localparam [2:0] AES_128 = 3'b001;
	localparam [2:0] AES_192 = 3'b010;
	localparam [2:0] AES_256 = 3'b100;
	reg [2:0] aes_cipher_ctrl_ns;
	reg [2:0] aes_cipher_ctrl_cs;
	reg [3:0] round_d;
	reg [3:0] round_q;
	reg [3:0] num_rounds_d;
	reg [3:0] num_rounds_q;
	wire [3:0] num_rounds_regular;
	reg dec_key_gen_d;
	reg dec_key_gen_q;
	reg key_clear_d;
	reg key_clear_q;
	reg data_out_clear_d;
	reg data_out_clear_q;
	always @(*) begin : aes_cipher_ctrl_fsm
		in_ready_o = 1'b0;
		out_valid_o = 1'b0;
		state_sel_o = STATE_ROUND;
		state_we_o = 1'b0;
		add_rk_sel_o = ADD_RK_ROUND;
		key_full_sel_o = KEY_FULL_ROUND;
		key_full_we_o = 1'b0;
		key_dec_sel_o = KEY_DEC_EXPAND;
		key_dec_we_o = 1'b0;
		key_expand_step_o = 1'b0;
		key_expand_clear_o = 1'b0;
		key_words_sel_o = KEY_WORDS_ZERO;
		round_key_sel_o = ROUND_KEY_DIRECT;
		aes_cipher_ctrl_ns = aes_cipher_ctrl_cs;
		round_d = round_q;
		num_rounds_d = num_rounds_q;
		dec_key_gen_d = dec_key_gen_q;
		key_clear_d = key_clear_q;
		data_out_clear_d = data_out_clear_q;
		case (aes_cipher_ctrl_cs)
			IDLE: begin
				dec_key_gen_d = 1'b0;
				in_ready_o = 1'b1;
				if (in_valid_i)
					if (start_i) begin
						dec_key_gen_d = dec_key_gen_i;
						state_sel_o = (dec_key_gen_d ? STATE_CLEAR : STATE_INIT);
						state_we_o = 1'b1;
						key_expand_clear_o = 1'b1;
						key_full_sel_o = (dec_key_gen_d ? KEY_FULL_ENC_INIT : (op_i == CIPH_FWD ? KEY_FULL_ENC_INIT : KEY_FULL_DEC_INIT));
						key_full_we_o = 1'b1;
						round_d = 1'sb0;
						num_rounds_d = (key_len_i == AES_128 ? 4'd10 : (key_len_i == AES_192 ? 4'd12 : 4'd14));
						aes_cipher_ctrl_ns = INIT;
					end
					else if (key_clear_i || data_out_clear_i) begin
						key_clear_d = key_clear_i;
						data_out_clear_d = data_out_clear_i;
						aes_cipher_ctrl_ns = CLEAR;
					end
			end
			INIT: begin
				state_we_o = ~dec_key_gen_q;
				add_rk_sel_o = ADD_RK_INIT;
				key_words_sel_o = (dec_key_gen_q ? KEY_WORDS_ZERO : (key_len_i == AES_128 ? KEY_WORDS_0123 : ((key_len_i == AES_192) && (op_i == CIPH_FWD) ? KEY_WORDS_0123 : ((key_len_i == AES_192) && (op_i == CIPH_INV) ? KEY_WORDS_2345 : ((key_len_i == AES_256) && (op_i == CIPH_FWD) ? KEY_WORDS_0123 : ((key_len_i == AES_256) && (op_i == CIPH_INV) ? KEY_WORDS_4567 : KEY_WORDS_ZERO))))));
				if (key_len_i != AES_256) begin
					key_expand_step_o = 1'b1;
					key_full_we_o = 1'b1;
				end
				aes_cipher_ctrl_ns = ROUND;
			end
			ROUND: begin
				state_we_o = ~dec_key_gen_q;
				key_words_sel_o = (dec_key_gen_q ? KEY_WORDS_ZERO : (key_len_i == AES_128 ? KEY_WORDS_0123 : ((key_len_i == AES_192) && (op_i == CIPH_FWD) ? KEY_WORDS_2345 : ((key_len_i == AES_192) && (op_i == CIPH_INV) ? KEY_WORDS_0123 : ((key_len_i == AES_256) && (op_i == CIPH_FWD) ? KEY_WORDS_4567 : ((key_len_i == AES_256) && (op_i == CIPH_INV) ? KEY_WORDS_0123 : KEY_WORDS_ZERO))))));
				key_expand_step_o = 1'b1;
				key_full_we_o = 1'b1;
				round_key_sel_o = (op_i == CIPH_FWD ? ROUND_KEY_DIRECT : ROUND_KEY_MIXED);
				round_d = round_q + 4'b1;
				if (round_q == num_rounds_regular) begin
					aes_cipher_ctrl_ns = FINISH;
					if (dec_key_gen_q) begin
						key_dec_we_o = 1'b1;
						out_valid_o = 1'b1;
						if (out_ready_i) begin
							dec_key_gen_d = 1'b0;
							aes_cipher_ctrl_ns = IDLE;
						end
					end
				end
			end
			FINISH: begin
				key_words_sel_o = (dec_key_gen_q ? KEY_WORDS_ZERO : (key_len_i == AES_128 ? KEY_WORDS_0123 : ((key_len_i == AES_192) && (op_i == CIPH_FWD) ? KEY_WORDS_2345 : ((key_len_i == AES_192) && (op_i == CIPH_INV) ? KEY_WORDS_0123 : ((key_len_i == AES_256) && (op_i == CIPH_FWD) ? KEY_WORDS_4567 : ((key_len_i == AES_256) && (op_i == CIPH_INV) ? KEY_WORDS_0123 : KEY_WORDS_ZERO))))));
				add_rk_sel_o = ADD_RK_FINAL;
				out_valid_o = 1'b1;
				if (out_ready_i) begin
					state_we_o = 1'b1;
					state_sel_o = STATE_CLEAR;
					dec_key_gen_d = 1'b0;
					aes_cipher_ctrl_ns = IDLE;
				end
			end
			CLEAR: begin
				if (key_clear_q) begin
					key_full_sel_o = KEY_FULL_CLEAR;
					key_full_we_o = 1'b1;
					key_dec_sel_o = KEY_DEC_CLEAR;
					key_dec_we_o = 1'b1;
				end
				if (data_out_clear_q) begin
					add_rk_sel_o = ADD_RK_INIT;
					key_words_sel_o = KEY_WORDS_ZERO;
					round_key_sel_o = ROUND_KEY_DIRECT;
				end
				out_valid_o = 1'b1;
				if (out_ready_i) begin
					key_clear_d = 1'b0;
					data_out_clear_d = 1'b0;
					aes_cipher_ctrl_ns = IDLE;
				end
			end
			default: aes_cipher_ctrl_ns = IDLE;
		endcase
	end
	always @(posedge clk_i or negedge rst_ni) begin : reg_fsm
		if (!rst_ni) begin
			aes_cipher_ctrl_cs <= IDLE;
			round_q <= 1'sb0;
			num_rounds_q <= 1'sb0;
			dec_key_gen_q <= 1'b0;
			key_clear_q <= 1'b0;
			data_out_clear_q <= 1'b0;
		end
		else begin
			aes_cipher_ctrl_cs <= aes_cipher_ctrl_ns;
			round_q <= round_d;
			num_rounds_q <= num_rounds_d;
			dec_key_gen_q <= dec_key_gen_d;
			key_clear_q <= key_clear_d;
			data_out_clear_q <= data_out_clear_d;
		end
	end
	assign num_rounds_regular = num_rounds_q - 4'd2;
	assign key_expand_op_o = (dec_key_gen_d || dec_key_gen_q ? CIPH_FWD : op_i);
	assign key_expand_round_o = round_d;
	assign dec_key_gen_o = dec_key_gen_q;
	assign key_clear_o = key_clear_q;
	assign data_out_clear_o = data_out_clear_q;
endmodule
