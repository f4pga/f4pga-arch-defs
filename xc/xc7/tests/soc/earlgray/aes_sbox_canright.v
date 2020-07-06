module aes_sbox_canright (
	op_i,
	data_i,
	data_o
);
	input wire [0:0] op_i;
	input wire [7:0] data_i;
	output wire [7:0] data_o;
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
			begin : sv2v_autoblock_146
				reg signed [31:0] j;
				for (j = 0; j < 4; j = j + 1)
					begin : sv2v_autoblock_147
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
		begin : sv2v_autoblock_148
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
			begin : sv2v_autoblock_149
				reg signed [31:0] i;
				for (i = 0; i < 8; i = i + 1)
					begin : sv2v_autoblock_150
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
	function automatic [1:0] aes_mul_gf2p2;
		input reg [1:0] g;
		input reg [1:0] d;
		reg [1:0] f;
		reg a;
		reg b;
		reg c;
		begin
			a = g[1] & d[1];
			b = ^g & ^d;
			c = g[0] & d[0];
			f[1] = a ^ b;
			f[0] = c ^ b;
			aes_mul_gf2p2 = f;
		end
	endfunction
	function automatic [1:0] aes_scale_omega2_gf2p2;
		input reg [1:0] g;
		reg [1:0] d;
		begin
			d[1] = g[0];
			d[0] = g[1] ^ g[0];
			aes_scale_omega2_gf2p2 = d;
		end
	endfunction
	function automatic [1:0] aes_scale_omega_gf2p2;
		input reg [1:0] g;
		reg [1:0] d;
		begin
			d[1] = g[1] ^ g[0];
			d[0] = g[1];
			aes_scale_omega_gf2p2 = d;
		end
	endfunction
	function automatic [1:0] aes_square_gf2p2;
		input reg [1:0] g;
		reg [1:0] d;
		begin
			d[1] = g[0];
			d[0] = g[1];
			aes_square_gf2p2 = d;
		end
	endfunction
	function automatic [3:0] aes_mul_gf2p4;
		input reg [3:0] gamma;
		input reg [3:0] delta;
		reg [3:0] theta;
		reg [1:0] a;
		reg [1:0] b;
		reg [1:0] c;
		begin
			a = aes_mul_gf2p2(gamma[3:2], delta[3:2]);
			b = aes_mul_gf2p2(gamma[3:2] ^ gamma[1:0], delta[3:2] ^ delta[1:0]);
			c = aes_mul_gf2p2(gamma[1:0], delta[1:0]);
			theta[3:2] = a ^ aes_scale_omega2_gf2p2(b);
			theta[1:0] = c ^ aes_scale_omega2_gf2p2(b);
			aes_mul_gf2p4 = theta;
		end
	endfunction
	function automatic [3:0] aes_square_scale_gf2p4_gf2p2;
		input reg [3:0] gamma;
		reg [3:0] delta;
		reg [1:0] a;
		reg [1:0] b;
		begin
			a = gamma[3:2] ^ gamma[1:0];
			b = aes_square_gf2p2(gamma[1:0]);
			delta[3:2] = aes_square_gf2p2(a);
			delta[1:0] = aes_scale_omega_gf2p2(b);
			aes_square_scale_gf2p4_gf2p2 = delta;
		end
	endfunction
	function automatic [3:0] aes_inverse_gf2p4;
		input reg [3:0] gamma;
		reg [3:0] delta;
		reg [1:0] a;
		reg [1:0] b;
		reg [1:0] c;
		reg [1:0] d;
		begin
			a = gamma[3:2] ^ gamma[1:0];
			b = aes_mul_gf2p2(gamma[3:2], gamma[1:0]);
			c = aes_scale_omega2_gf2p2(aes_square_gf2p2(a));
			d = aes_square_gf2p2(c ^ b);
			delta[3:2] = aes_mul_gf2p2(d, gamma[1:0]);
			delta[1:0] = aes_mul_gf2p2(d, gamma[3:2]);
			aes_inverse_gf2p4 = delta;
		end
	endfunction
	function automatic [7:0] aes_inverse_gf2p8;
		input reg [7:0] gamma;
		reg [7:0] delta;
		reg [3:0] a;
		reg [3:0] b;
		reg [3:0] c;
		reg [3:0] d;
		begin
			a = gamma[7:4] ^ gamma[3:0];
			b = aes_mul_gf2p4(gamma[7:4], gamma[3:0]);
			c = aes_square_scale_gf2p4_gf2p2(a);
			d = aes_inverse_gf2p4(c ^ b);
			delta[7:4] = aes_mul_gf2p4(d, gamma[3:0]);
			delta[3:0] = aes_mul_gf2p4(d, gamma[7:4]);
			aes_inverse_gf2p8 = delta;
		end
	endfunction
	wire [63:0] a2x = {8'h98, 8'hf3, 8'hf2, 8'h48, 8'h09, 8'h81, 8'ha9, 8'hff};
	wire [63:0] x2a = {8'h64, 8'h78, 8'h6e, 8'h8c, 8'h68, 8'h29, 8'hde, 8'h60};
	wire [63:0] x2s = {8'h58, 8'h2d, 8'h9e, 8'h0b, 8'hdc, 8'h04, 8'h03, 8'h24};
	wire [63:0] s2x = {8'h8c, 8'h79, 8'h05, 8'heb, 8'h12, 8'h04, 8'h51, 8'h53};
	wire [7:0] data_basis_x;
	wire [7:0] data_inverse;
	assign data_basis_x = (op_i == CIPH_FWD ? aes_mvm(data_i, a2x) : aes_mvm(data_i ^ 8'h63, s2x));
	assign data_inverse = aes_inverse_gf2p8(data_basis_x);
	assign data_o = (op_i == CIPH_FWD ? aes_mvm(data_inverse, x2s) ^ 8'h63 : aes_mvm(data_inverse, x2a));
endmodule
