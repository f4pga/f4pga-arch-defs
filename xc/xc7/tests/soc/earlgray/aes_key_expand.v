module aes_key_expand (
	clk_i,
	rst_ni,
	op_i,
	step_i,
	clear_i,
	round_i,
	key_len_i,
	key_i,
	key_o
);
	parameter AES192Enable = 1;
	parameter SBoxImpl = "lut";
	input wire clk_i;
	input wire rst_ni;
	input wire [0:0] op_i;
	input wire step_i;
	input wire clear_i;
	input wire [3:0] round_i;
	input wire [2:0] key_len_i;
	input wire [255:0] key_i;
	output wire [255:0] key_o;
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
			begin : sv2v_autoblock_152
				reg signed [31:0] j;
				for (j = 0; j < 4; j = j + 1)
					begin : sv2v_autoblock_153
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
		begin : sv2v_autoblock_154
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
			begin : sv2v_autoblock_155
				reg signed [31:0] i;
				for (i = 0; i < 8; i = i + 1)
					begin : sv2v_autoblock_156
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
	reg [7:0] rcon_d;
	reg [7:0] rcon_q;
	wire rcon_we;
	reg use_rcon;
	wire [3:0] rnd;
	reg [3:0] rnd_type;
	wire [31:0] spec_in_128;
	wire [31:0] spec_in_192;
	reg [31:0] rot_word_in;
	wire [31:0] rot_word_out;
	wire use_rot_word;
	wire [31:0] sub_word_in;
	wire [31:0] sub_word_out;
	wire [7:0] rcon_add_in;
	wire [7:0] rcon_add_out;
	wire [31:0] rcon_added;
	wire [31:0] irregular;
	reg [255:0] regular;
	assign rnd = round_i;
	always @(*) begin : get_rnd_type
		if (AES192Enable) begin
			rnd_type[0] = rnd == 0;
			rnd_type[1] = (((rnd == 1) || (rnd == 4)) || (rnd == 7)) || (rnd == 10);
			rnd_type[2] = (((rnd == 2) || (rnd == 5)) || (rnd == 8)) || (rnd == 11);
			rnd_type[3] = (((rnd == 3) || (rnd == 6)) || (rnd == 9)) || (rnd == 12);
		end
		else
			rnd_type = 1'sb0;
	end
	assign use_rot_word = ((key_len_i == AES_256) && (rnd[0] == 1'b0) ? 1'b0 : 1'b1);
	always @(*) begin : rcon_usage
		use_rcon = 1'b1;
		if (AES192Enable)
			if ((key_len_i == AES_192) && (((op_i == CIPH_FWD) && rnd_type[1]) || ((op_i == CIPH_INV) && (rnd_type[0] || rnd_type[3]))))
				use_rcon = 1'b0;
		if ((key_len_i == AES_256) && (rnd[0] == 1'b0))
			use_rcon = 1'b0;
	end
	always @(*) begin : rcon_update
		rcon_d = rcon_q;
		if (clear_i)
			rcon_d = (op_i == CIPH_FWD ? 8'h01 : ((op_i == CIPH_INV) && (key_len_i == AES_128) ? 8'h36 : ((op_i == CIPH_INV) && (key_len_i == AES_192) ? 8'h80 : ((op_i == CIPH_INV) && (key_len_i == AES_256) ? 8'h40 : 8'h01))));
		else
			rcon_d = (op_i == CIPH_FWD ? aes_mul2(rcon_q) : (op_i == CIPH_INV ? aes_div2(rcon_q) : 8'h01));
	end
	assign rcon_we = clear_i | (step_i & use_rcon);
	always @(posedge clk_i or negedge rst_ni) begin : reg_rcon
		if (!rst_ni)
			rcon_q <= 1'sb0;
		else if (rcon_we)
			rcon_q <= rcon_d;
	end
	assign spec_in_128 = key_i[96+:32] ^ key_i[64+:32];
	assign spec_in_192 = (AES192Enable ? (key_i[160+:32] ^ key_i[32+:32]) ^ key_i[0+:32] : 1'sb0);
	always @(*) begin : rot_word_in_mux
		case (key_len_i)
			AES_128:
				case (op_i)
					CIPH_FWD: rot_word_in = key_i[96+:32];
					CIPH_INV: rot_word_in = spec_in_128;
					default: rot_word_in = key_i[96+:32];
				endcase
			AES_192:
				if (AES192Enable)
					case (op_i)
						CIPH_FWD: rot_word_in = (rnd_type[0] ? key_i[160+:32] : (rnd_type[2] ? key_i[160+:32] : (rnd_type[3] ? spec_in_192 : key_i[96+:32])));
						CIPH_INV: rot_word_in = (rnd_type[1] ? key_i[96+:32] : (rnd_type[2] ? key_i[32+:32] : key_i[96+:32]));
						default: rot_word_in = key_i[96+:32];
					endcase
				else
					rot_word_in = key_i[96+:32];
			AES_256:
				case (op_i)
					CIPH_FWD: rot_word_in = key_i[224+:32];
					CIPH_INV: rot_word_in = key_i[96+:32];
					default: rot_word_in = key_i[224+:32];
				endcase
			default: rot_word_in = key_i[96+:32];
		endcase
	end
	assign rot_word_out = aes_circ_byte_shift(rot_word_in, 3);
	assign sub_word_in = (use_rot_word ? rot_word_out : rot_word_in);
	generate
		genvar i;
		for (i = 0; i < 4; i = i + 1) begin : gen_sbox
			aes_sbox #(.SBoxImpl(SBoxImpl)) aes_sbox_i(
				.op_i(CIPH_FWD),
				.data_i(sub_word_in[8 * i+:8]),
				.data_o(sub_word_out[8 * i+:8])
			);
		end
	endgenerate
	assign rcon_add_in = sub_word_out[7:0];
	assign rcon_add_out = rcon_add_in ^ rcon_q;
	assign rcon_added = {sub_word_out[31:8], rcon_add_out};
	assign irregular = (use_rcon ? rcon_added : sub_word_out);
	always @(*) begin : drive_regular
		case (key_len_i)
			AES_128: begin
				regular[128+:128] = key_i[0+:128];
				regular[0+:32] = irregular ^ key_i[0+:32];
				case (op_i)
					CIPH_FWD: begin : sv2v_autoblock_157
						reg signed [31:0] i;
						for (i = 1; i < 4; i = i + 1)
							regular[i * 32+:32] = regular[(i - 1) * 32+:32] ^ key_i[i * 32+:32];
					end
					CIPH_INV: begin : sv2v_autoblock_158
						reg signed [31:0] i;
						for (i = 1; i < 4; i = i + 1)
							regular[i * 32+:32] = key_i[(i - 1) * 32+:32] ^ key_i[i * 32+:32];
					end
					default: regular = {key_i[0+:128], key_i[128+:128]};
				endcase
			end
			AES_192: begin
				regular[192+:64] = key_i[64+:64];
				if (AES192Enable)
					case (op_i)
						CIPH_FWD:
							if (rnd_type[0]) begin
								regular[0+:128] = key_i[64+:128];
								regular[128+:32] = irregular ^ key_i[0+:32];
								regular[160+:32] = regular[128+:32] ^ key_i[32+:32];
							end
							else begin
								regular[0+:64] = key_i[128+:64];
								begin : sv2v_autoblock_159
									reg signed [31:0] i;
									for (i = 0; i < 4; i = i + 1)
										if (((i == 0) && rnd_type[2]) || ((i == 2) && rnd_type[3]))
											regular[(i + 2) * 32+:32] = irregular ^ key_i[i * 32+:32];
										else
											regular[(i + 2) * 32+:32] = regular[(i + 1) * 32+:32] ^ key_i[i * 32+:32];
								end
							end
						CIPH_INV:
							if (rnd_type[0]) begin
								regular[64+:128] = key_i[0+:128];
								begin : sv2v_autoblock_160
									reg signed [31:0] i;
									for (i = 0; i < 2; i = i + 1)
										regular[i * 32+:32] = key_i[(3 + i) * 32+:32] ^ key_i[((3 + i) + 1) * 32+:32];
								end
							end
							else begin
								regular[128+:64] = key_i[0+:64];
								begin : sv2v_autoblock_161
									reg signed [31:0] i;
									for (i = 0; i < 4; i = i + 1)
										if (((i == 2) && rnd_type[1]) || ((i == 0) && rnd_type[2]))
											regular[i * 32+:32] = irregular ^ key_i[(i + 2) * 32+:32];
										else
											regular[i * 32+:32] = key_i[(i + 1) * 32+:32] ^ key_i[(i + 2) * 32+:32];
								end
							end
						default: regular = {key_i[0+:128], key_i[128+:128]};
					endcase
				else
					regular = {key_i[0+:128], key_i[128+:128]};
			end
			AES_256:
				case (op_i)
					CIPH_FWD:
						if (rnd == 0)
							regular = {key_i[0+:128], key_i[128+:128]};
						else begin
							regular[0+:128] = key_i[128+:128];
							regular[128+:32] = irregular ^ key_i[0+:32];
							begin : sv2v_autoblock_162
								reg signed [31:0] i;
								for (i = 1; i < 4; i = i + 1)
									regular[(i + 4) * 32+:32] = regular[((i + 4) - 1) * 32+:32] ^ key_i[i * 32+:32];
							end
						end
					CIPH_INV:
						if (rnd == 0)
							regular = {key_i[0+:128], key_i[128+:128]};
						else begin
							regular[128+:128] = key_i[0+:128];
							regular[0+:32] = irregular ^ key_i[128+:32];
							begin : sv2v_autoblock_163
								reg signed [31:0] i;
								for (i = 0; i < 3; i = i + 1)
									regular[(i + 1) * 32+:32] = key_i[(4 + i) * 32+:32] ^ key_i[((4 + i) + 1) * 32+:32];
							end
						end
					default: regular = {key_i[0+:128], key_i[128+:128]};
				endcase
			default: regular = {key_i[0+:128], key_i[128+:128]};
		endcase
	end
	assign key_o = regular;
endmodule
