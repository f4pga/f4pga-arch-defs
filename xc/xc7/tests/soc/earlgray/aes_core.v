module aes_core (
	clk_i,
	rst_ni,
	reg2hw,
	hw2reg
);
	parameter AES192Enable = 1;
	parameter SBoxImpl = "lut";
	input wire clk_i;
	input wire rst_ni;
	input wire [539:0] reg2hw;
	output reg [536:0] hw2reg;
	parameter signed [31:0] NumRegsKey = 8;
	parameter signed [31:0] NumRegsData = 4;
	parameter [6:0] AES_KEY0_OFFSET = 7'h 0;
	parameter [6:0] AES_KEY1_OFFSET = 7'h 4;
	parameter [6:0] AES_KEY2_OFFSET = 7'h 8;
	parameter [6:0] AES_KEY3_OFFSET = 7'h c;
	parameter [6:0] AES_KEY4_OFFSET = 7'h 10;
	parameter [6:0] AES_KEY5_OFFSET = 7'h 14;
	parameter [6:0] AES_KEY6_OFFSET = 7'h 18;
	parameter [6:0] AES_KEY7_OFFSET = 7'h 1c;
	parameter [6:0] AES_DATA_IN0_OFFSET = 7'h 20;
	parameter [6:0] AES_DATA_IN1_OFFSET = 7'h 24;
	parameter [6:0] AES_DATA_IN2_OFFSET = 7'h 28;
	parameter [6:0] AES_DATA_IN3_OFFSET = 7'h 2c;
	parameter [6:0] AES_DATA_OUT0_OFFSET = 7'h 30;
	parameter [6:0] AES_DATA_OUT1_OFFSET = 7'h 34;
	parameter [6:0] AES_DATA_OUT2_OFFSET = 7'h 38;
	parameter [6:0] AES_DATA_OUT3_OFFSET = 7'h 3c;
	parameter [6:0] AES_CTRL_OFFSET = 7'h 40;
	parameter [6:0] AES_TRIGGER_OFFSET = 7'h 44;
	parameter [6:0] AES_STATUS_OFFSET = 7'h 48;
	parameter [75:0] AES_PERMIT = {4'b 1111, 4'b 1111, 4'b 1111, 4'b 1111, 4'b 1111, 4'b 1111, 4'b 1111, 4'b 1111, 4'b 1111, 4'b 1111, 4'b 1111, 4'b 1111, 4'b 1111, 4'b 1111, 4'b 1111, 4'b 1111, 4'b 0001, 4'b 0001, 4'b 0001};
	localparam AES_KEY0 = 0;
	localparam AES_KEY1 = 1;
	localparam AES_DATA_IN2 = 10;
	localparam AES_DATA_IN3 = 11;
	localparam AES_DATA_OUT0 = 12;
	localparam AES_DATA_OUT1 = 13;
	localparam AES_DATA_OUT2 = 14;
	localparam AES_DATA_OUT3 = 15;
	localparam AES_CTRL = 16;
	localparam AES_TRIGGER = 17;
	localparam AES_STATUS = 18;
	localparam AES_KEY2 = 2;
	localparam AES_KEY3 = 3;
	localparam AES_KEY4 = 4;
	localparam AES_KEY5 = 5;
	localparam AES_KEY6 = 6;
	localparam AES_KEY7 = 7;
	localparam AES_DATA_IN0 = 8;
	localparam AES_DATA_IN1 = 9;
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
			begin : sv2v_autoblock_157
				reg signed [31:0] j;
				for (j = 0; j < 4; j = j + 1)
					begin : sv2v_autoblock_158
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
		begin : sv2v_autoblock_159
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
			begin : sv2v_autoblock_160
				reg signed [31:0] i;
				for (i = 0; i < 8; i = i + 1)
					begin : sv2v_autoblock_161
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
	reg [127:0] data_in;
	reg [3:0] data_in_qe;
	wire data_in_we;
	reg [255:0] key_init;
	reg [7:0] key_init_qe;
	wire ctrl_qe;
	wire ctrl_we;
	wire [0:0] aes_op_d;
	reg [0:0] aes_op_q;
	wire [0:0] cipher_op;
	wire [2:0] key_len;
	reg [2:0] key_len_d;
	reg [2:0] key_len_q;
	reg manual_operation_q;
	wire [127:0] state_init;
	wire [127:0] state_done;
	reg [255:0] key_init_d;
	reg [255:0] key_init_q;
	wire [7:0] key_init_we;
	wire [0:0] key_init_sel;
	wire [127:0] data_out_d;
	reg [127:0] data_out_q;
	wire data_out_we;
	reg [3:0] data_out_re;
	wire cipher_in_valid;
	wire cipher_in_ready;
	wire cipher_out_valid;
	wire cipher_out_ready;
	wire cipher_start;
	wire cipher_dec_key_gen;
	wire cipher_dec_key_gen_busy;
	wire cipher_key_clear;
	wire cipher_key_clear_busy;
	wire cipher_data_out_clear;
	wire cipher_data_out_clear_busy;
	reg [127:0] unused_data_out_q;
	always @(*) begin : key_init_get
		begin : sv2v_autoblock_162
			reg signed [31:0] i;
			for (i = 0; i < 8; i = i + 1)
				begin
					key_init[i * 32+:32] = reg2hw[276 + ((i * 33) + 32)-:32];
					key_init_qe[i] = reg2hw[276 + (i * 33)];
				end
		end
	end
	always @(*) begin : data_in_get
		begin : sv2v_autoblock_163
			reg signed [31:0] i;
			for (i = 0; i < 4; i = i + 1)
				begin
					data_in[i * 32+:32] = reg2hw[144 + ((i * 33) + 32)-:32];
					data_in_qe[i] = reg2hw[144 + (i * 33)];
				end
		end
	end
	always @(*) begin : data_out_get
		begin : sv2v_autoblock_164
			reg signed [31:0] i;
			for (i = 0; i < 4; i = i + 1)
				begin
					unused_data_out_q[i * 32+:32] = reg2hw[12 + ((i * 33) + 32)-:32];
					data_out_re[i] = reg2hw[12 + (i * 33)];
				end
		end
	end
	assign aes_op_d = sv2v_cast_1(reg2hw[11]);
	assign key_len = sv2v_cast_3(reg2hw[9-:3]);
	always @(*) begin : get_key_len
		case (key_len)
			AES_128: key_len_d = AES_128;
			AES_256: key_len_d = AES_256;
			AES_192: key_len_d = (AES192Enable ? AES_192 : AES_128);
			default: key_len_d = AES_128;
		endcase
	end
	assign ctrl_qe = (reg2hw[10] & reg2hw[6]) & reg2hw[4];
	assign state_init = aes_transpose(data_in);
	always @(*) begin : key_init_mux
		case (key_init_sel)
			KEY_INIT_INPUT: key_init_d = key_init;
			KEY_INIT_CLEAR: key_init_d = 1'sb0;
			default: key_init_d = 1'sb0;
		endcase
	end
	always @(posedge clk_i or negedge rst_ni) begin : key_init_reg
		if (!rst_ni)
			key_init_q <= 1'sb0;
		else begin : sv2v_autoblock_165
			reg signed [31:0] i;
			for (i = 0; i < 8; i = i + 1)
				if (key_init_we[i])
					key_init_q[i * 32+:32] <= key_init_d[i * 32+:32];
		end
	end
	assign cipher_op = (aes_op_q == AES_ENC ? CIPH_FWD : CIPH_INV);
	aes_cipher_core #(
		.AES192Enable(AES192Enable),
		.SBoxImpl(SBoxImpl)
	) aes_cipher_core(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.in_valid_i(cipher_in_valid),
		.in_ready_o(cipher_in_ready),
		.out_valid_o(cipher_out_valid),
		.out_ready_i(cipher_out_ready),
		.op_i(cipher_op),
		.key_len_i(key_len_q),
		.start_i(cipher_start),
		.dec_key_gen_i(cipher_dec_key_gen),
		.dec_key_gen_o(cipher_dec_key_gen_busy),
		.key_clear_i(cipher_key_clear),
		.key_clear_o(cipher_key_clear_busy),
		.data_out_clear_i(cipher_data_out_clear),
		.data_out_clear_o(cipher_data_out_clear_busy),
		.state_init_i(state_init),
		.key_init_i(key_init_q),
		.state_o(state_done)
	);
	aes_control aes_control(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.cipher_op_i(cipher_op),
		.manual_operation_i(manual_operation_q),
		.start_i(reg2hw[3]),
		.key_clear_i(reg2hw[2]),
		.data_in_clear_i(reg2hw[1]),
		.data_out_clear_i(reg2hw[0]),
		.data_in_qe_i(data_in_qe),
		.key_init_qe_i(key_init_qe),
		.data_out_re_i(data_out_re),
		.data_in_we_o(data_in_we),
		.data_out_we_o(data_out_we),
		.cipher_in_valid_o(cipher_in_valid),
		.cipher_in_ready_i(cipher_in_ready),
		.cipher_out_valid_i(cipher_out_valid),
		.cipher_out_ready_o(cipher_out_ready),
		.cipher_start_o(cipher_start),
		.cipher_dec_key_gen_o(cipher_dec_key_gen),
		.cipher_dec_key_gen_i(cipher_dec_key_gen_busy),
		.cipher_key_clear_o(cipher_key_clear),
		.cipher_key_clear_i(cipher_key_clear_busy),
		.cipher_data_out_clear_o(cipher_data_out_clear),
		.cipher_data_out_clear_i(cipher_data_out_clear_busy),
		.key_init_sel_o(key_init_sel),
		.key_init_we_o(key_init_we),
		.start_o(hw2reg[15]),
		.start_we_o(hw2reg[14]),
		.key_clear_o(hw2reg[13]),
		.key_clear_we_o(hw2reg[12]),
		.data_in_clear_o(hw2reg[11]),
		.data_in_clear_we_o(hw2reg[10]),
		.data_out_clear_o(hw2reg[9]),
		.data_out_clear_we_o(hw2reg[8]),
		.output_valid_o(hw2reg[3]),
		.output_valid_we_o(hw2reg[2]),
		.input_ready_o(hw2reg[1]),
		.input_ready_we_o(hw2reg[0]),
		.idle_o(hw2reg[7]),
		.idle_we_o(hw2reg[6]),
		.stall_o(hw2reg[5]),
		.stall_we_o(hw2reg[4])
	);
	always @(*) begin : data_in_reg_clear
		begin : sv2v_autoblock_166
			reg signed [31:0] i;
			for (i = 0; i < 4; i = i + 1)
				begin
					hw2reg[149 + ((i * 33) + 32)-:32] = 1'sb0;
					hw2reg[149 + (i * 33)] = data_in_we;
				end
		end
	end
	assign ctrl_we = ctrl_qe & hw2reg[7];
	always @(posedge clk_i or negedge rst_ni) begin : ctrl_reg
		if (!rst_ni) begin
			aes_op_q <= AES_ENC;
			key_len_q <= AES_128;
			manual_operation_q <= 1'sb0;
		end
		else if (ctrl_we) begin
			aes_op_q <= aes_op_d;
			key_len_q <= key_len_d;
			manual_operation_q <= reg2hw[5];
		end
	end
	assign data_out_d = aes_transpose(state_done);
	always @(posedge clk_i or negedge rst_ni) begin : data_out_reg
		if (!rst_ni)
			data_out_q <= 1'sb0;
		else if (data_out_we)
			data_out_q <= data_out_d;
	end
	always @(*) begin : key_reg_put
		begin : sv2v_autoblock_167
			reg signed [31:0] i;
			for (i = 0; i < 8; i = i + 1)
				hw2reg[281 + ((i * 32) + 31)-:32] = key_init_q[i * 32+:32];
		end
	end
	always @(*) begin : data_out_put
		begin : sv2v_autoblock_168
			reg signed [31:0] i;
			for (i = 0; i < 4; i = i + 1)
				hw2reg[21 + ((i * 32) + 31)-:32] = data_out_q[i * 32+:32];
		end
	end
	always @(*) hw2reg[19-:3] = key_len_q;
	always @(*) hw2reg[20] = aes_op_q;
	always @(*) hw2reg[16] = manual_operation_q;
	function automatic [0:0] sv2v_cast_1;
		input reg [0:0] inp;
		sv2v_cast_1 = inp;
	endfunction
	function automatic [2:0] sv2v_cast_3;
		input reg [2:0] inp;
		sv2v_cast_3 = inp;
	endfunction
endmodule
