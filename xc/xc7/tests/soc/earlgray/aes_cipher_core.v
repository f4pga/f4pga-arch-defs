module aes_cipher_core (
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
	state_init_i,
	key_init_i,
	state_o
);
	parameter AES192Enable = 1;
	parameter SBoxImpl = "lut";
	input wire clk_i;
	input wire rst_ni;
	input wire in_valid_i;
	output wire in_ready_o;
	output wire out_valid_o;
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
	input wire [127:0] state_init_i;
	input wire [255:0] key_init_i;
	output wire [127:0] state_o;
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
			begin : sv2v_autoblock_155
				reg signed [31:0] j;
				for (j = 0; j < 4; j = j + 1)
					begin : sv2v_autoblock_156
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
		begin : sv2v_autoblock_157
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
			begin : sv2v_autoblock_158
				reg signed [31:0] i;
				for (i = 0; i < 8; i = i + 1)
					begin : sv2v_autoblock_159
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
	reg [127:0] state_d;
	reg [127:0] state_q;
	wire state_we;
	wire [1:0] state_sel;
	wire [127:0] sub_bytes_out;
	wire [127:0] shift_rows_out;
	wire [127:0] mix_columns_out;
	reg [127:0] add_round_key_in;
	wire [127:0] add_round_key_out;
	wire [1:0] add_round_key_in_sel;
	reg [255:0] key_full_d;
	reg [255:0] key_full_q;
	wire key_full_we;
	wire [1:0] key_full_sel;
	reg [255:0] key_dec_d;
	reg [255:0] key_dec_q;
	wire key_dec_we;
	wire [0:0] key_dec_sel;
	wire [255:0] key_expand_out;
	wire [0:0] key_expand_op;
	wire key_expand_step;
	wire key_expand_clear;
	wire [3:0] key_expand_round;
	wire [1:0] key_words_sel;
	reg [127:0] key_words;
	wire [127:0] key_bytes;
	wire [127:0] key_mix_columns_out;
	reg [127:0] round_key;
	wire [0:0] round_key_sel;
	always @(*) begin : state_mux
		case (state_sel)
			STATE_INIT: state_d = state_init_i;
			STATE_ROUND: state_d = add_round_key_out;
			STATE_CLEAR: state_d = 1'sb0;
			default: state_d = 1'sb0;
		endcase
	end
	always @(posedge clk_i or negedge rst_ni) begin : state_reg
		if (!rst_ni)
			state_q <= 1'sb0;
		else if (state_we)
			state_q <= state_d;
	end
	aes_sub_bytes #(.SBoxImpl(SBoxImpl)) aes_sub_bytes(
		.op_i(op_i),
		.data_i(state_q),
		.data_o(sub_bytes_out)
	);
	aes_shift_rows aes_shift_rows(
		.op_i(op_i),
		.data_i(sub_bytes_out),
		.data_o(shift_rows_out)
	);
	aes_mix_columns aes_mix_columns(
		.op_i(op_i),
		.data_i(shift_rows_out),
		.data_o(mix_columns_out)
	);
	always @(*) begin : add_round_key_in_mux
		case (add_round_key_in_sel)
			ADD_RK_INIT: add_round_key_in = state_q;
			ADD_RK_ROUND: add_round_key_in = mix_columns_out;
			ADD_RK_FINAL: add_round_key_in = shift_rows_out;
			default: add_round_key_in = state_q;
		endcase
	end
	assign add_round_key_out = add_round_key_in ^ round_key;
	always @(*) begin : key_full_mux
		case (key_full_sel)
			KEY_FULL_ENC_INIT: key_full_d = key_init_i;
			KEY_FULL_DEC_INIT: key_full_d = key_dec_q;
			KEY_FULL_ROUND: key_full_d = key_expand_out;
			KEY_FULL_CLEAR: key_full_d = 1'sb0;
			default: key_full_d = 1'sb0;
		endcase
	end
	always @(posedge clk_i or negedge rst_ni) begin : key_full_reg
		if (!rst_ni)
			key_full_q <= 1'sb0;
		else if (key_full_we)
			key_full_q <= key_full_d;
	end
	always @(*) begin : key_dec_mux
		case (key_dec_sel)
			KEY_DEC_EXPAND: key_dec_d = key_expand_out;
			KEY_DEC_CLEAR: key_dec_d = 1'sb0;
			default: key_dec_d = 1'sb0;
		endcase
	end
	always @(posedge clk_i or negedge rst_ni) begin : key_dec_reg
		if (!rst_ni)
			key_dec_q <= 1'sb0;
		else if (key_dec_we)
			key_dec_q <= key_dec_d;
	end
	aes_key_expand #(
		.AES192Enable(AES192Enable),
		.SBoxImpl(SBoxImpl)
	) aes_key_expand(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.op_i(key_expand_op),
		.step_i(key_expand_step),
		.clear_i(key_expand_clear),
		.round_i(key_expand_round),
		.key_len_i(key_len_i),
		.key_i(key_full_q),
		.key_o(key_expand_out)
	);
	always @(*) begin : key_words_mux
		case (key_words_sel)
			KEY_WORDS_0123: key_words = key_full_q[0+:128];
			KEY_WORDS_2345: key_words = (AES192Enable ? key_full_q[64+:128] : 1'sb0);
			KEY_WORDS_4567: key_words = key_full_q[128+:128];
			KEY_WORDS_ZERO: key_words = 1'sb0;
			default: key_words = 1'sb0;
		endcase
	end
	assign key_bytes = aes_transpose(key_words);
	aes_mix_columns aes_key_mix_columns(
		.op_i(CIPH_INV),
		.data_i(key_bytes),
		.data_o(key_mix_columns_out)
	);
	always @(*) begin : round_key_mux
		case (round_key_sel)
			ROUND_KEY_DIRECT: round_key = key_bytes;
			ROUND_KEY_MIXED: round_key = key_mix_columns_out;
			default: round_key = key_bytes;
		endcase
	end
	aes_cipher_control aes_cipher_control(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.in_valid_i(in_valid_i),
		.in_ready_o(in_ready_o),
		.out_valid_o(out_valid_o),
		.out_ready_i(out_ready_i),
		.op_i(op_i),
		.key_len_i(key_len_i),
		.start_i(start_i),
		.dec_key_gen_i(dec_key_gen_i),
		.dec_key_gen_o(dec_key_gen_o),
		.key_clear_i(key_clear_i),
		.key_clear_o(key_clear_o),
		.data_out_clear_i(data_out_clear_i),
		.data_out_clear_o(data_out_clear_o),
		.state_sel_o(state_sel),
		.state_we_o(state_we),
		.add_rk_sel_o(add_round_key_in_sel),
		.key_expand_op_o(key_expand_op),
		.key_full_sel_o(key_full_sel),
		.key_full_we_o(key_full_we),
		.key_dec_sel_o(key_dec_sel),
		.key_dec_we_o(key_dec_we),
		.key_expand_step_o(key_expand_step),
		.key_expand_clear_o(key_expand_clear),
		.key_expand_round_o(key_expand_round),
		.key_words_sel_o(key_words_sel),
		.round_key_sel_o(round_key_sel)
	);
	assign state_o = add_round_key_out;
endmodule
