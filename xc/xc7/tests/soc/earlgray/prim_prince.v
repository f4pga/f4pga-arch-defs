module prim_prince (
	data_i,
	key_i,
	dec_i,
	data_o
);
	parameter signed [31:0] DataWidth = 64;
	parameter signed [31:0] KeyWidth = 128;
	parameter signed [31:0] NumRoundsHalf = 5;
	input [DataWidth - 1:0] data_i;
	input [KeyWidth - 1:0] key_i;
	input dec_i;
	output reg [DataWidth - 1:0] data_o;
	localparam [63:0] SBox4 = {4'h4, 4'hD, 4'h5, 4'hE, 4'h0, 4'h8, 4'h7, 4'h6, 4'h1, 4'h9, 4'hC, 4'hA, 4'h2, 4'h3, 4'hF, 4'hB};
	localparam [63:0] SBox4Inv = {4'h1, 4'hC, 4'hE, 4'h5, 4'h0, 4'h4, 4'h6, 4'hA, 4'h9, 4'h8, 4'hD, 4'hF, 4'h2, 4'h3, 4'h7, 4'hB};
	localparam [63:0] Shiftrows64 = {4'hB, 4'h6, 4'h1, 4'hC, 4'h7, 4'h2, 4'hD, 4'h8, 4'h3, 4'hE, 4'h9, 4'h4, 4'hF, 4'hA, 4'h5, 4'h0};
	localparam [63:0] Shiftrows64Inv = {4'h3, 4'h6, 4'h9, 4'hC, 4'hF, 4'h2, 4'h5, 4'h8, 4'hB, 4'hE, 4'h1, 4'h4, 4'h7, 4'hA, 4'hD, 4'h0};
	localparam [767:0] RoundConst = {64'hC0AC29B7C97C50DD, 64'hD3B5A399CA0C2399, 64'h64A51195E0E3610D, 64'hC882D32F25323C54, 64'h85840851F1AC43AA, 64'h7EF84F78FD955CB1, 64'hBE5466CF34E90C6C, 64'h452821E638D01377, 64'h082EFA98EC4E6C89, 64'hA4093822299F31D0, 64'h13198A2E03707344, 64'h0000000000000000};
	localparam [63:0] AlphaConst = 64'hC0AC29B7C97C50DD;
	function automatic [DataWidth - 1:0] sbox4_layer;
		input reg [DataWidth - 1:0] state_in;
		reg [DataWidth - 1:0] state_out;
		begin
			begin : sv2v_autoblock_147
				reg signed [31:0] k;
				for (k = 0; k < (DataWidth / 4); k = k + 1)
					state_out[k * 4+:4] = SBox4[state_in[k * 4+:4] * 4+:4];
			end
			sbox4_layer = state_out;
		end
	endfunction
	function automatic [DataWidth - 1:0] sbox4_inv_layer;
		input reg [DataWidth - 1:0] state_in;
		reg [DataWidth - 1:0] state_out;
		begin
			begin : sv2v_autoblock_148
				reg signed [31:0] k;
				for (k = 0; k < (DataWidth / 4); k = k + 1)
					state_out[k * 4+:4] = SBox4Inv[state_in[k * 4+:4] * 4+:4];
			end
			sbox4_inv_layer = state_out;
		end
	endfunction
	function automatic [DataWidth - 1:0] shiftrows_layer;
		input reg [DataWidth - 1:0] state_in;
		reg [DataWidth - 1:0] state_out;
		begin
			if (DataWidth == 64) begin : sv2v_autoblock_149
				reg signed [31:0] k;
				for (k = 0; k < (DataWidth / 4); k = k + 1)
					state_out[k * 4+:4] = state_in[Shiftrows64[k * 4+:4] * 4+:4];
			end
			else begin : sv2v_autoblock_150
				reg signed [31:0] k;
				for (k = 0; k < (DataWidth / 2); k = k + 1)
					state_out[k * 2+:2] = state_in[Shiftrows64[k * 4+:4] * 2+:2];
			end
			shiftrows_layer = state_out;
		end
	endfunction
	function automatic [DataWidth - 1:0] shiftrows_inv_layer;
		input reg [DataWidth - 1:0] state_in;
		reg [DataWidth - 1:0] state_out;
		begin
			if (DataWidth == 64) begin : sv2v_autoblock_151
				reg signed [31:0] k;
				for (k = 0; k < (DataWidth / 4); k = k + 1)
					state_out[k * 4+:4] = state_in[Shiftrows64Inv[k * 4+:4] * 4+:4];
			end
			else begin : sv2v_autoblock_152
				reg signed [31:0] k;
				for (k = 0; k < (DataWidth / 2); k = k + 1)
					state_out[k * 2+:2] = state_in[Shiftrows64Inv[k * 4+:4] * 2+:2];
			end
			shiftrows_inv_layer = state_out;
		end
	endfunction
	function automatic [3:0] nibble_red16;
		input reg [15:0] vect;
		nibble_red16 = ((vect[0+:4] ^ vect[4+:4]) ^ vect[8+:4]) ^ vect[12+:4];
	endfunction
	function automatic [DataWidth - 1:0] mult_prime_layer;
		input reg [DataWidth - 1:0] state_in;
		reg [DataWidth - 1:0] state_out;
		begin
			state_out[0+:4] = nibble_red16(state_in[0+:16] & 16'hEDB7);
			state_out[4+:4] = nibble_red16(state_in[0+:16] & 16'h7EDB);
			state_out[8+:4] = nibble_red16(state_in[0+:16] & 16'hB7ED);
			state_out[12+:4] = nibble_red16(state_in[0+:16] & 16'hDB7E);
			state_out[16+:4] = nibble_red16(state_in[16+:16] & 16'h7EDB);
			state_out[20+:4] = nibble_red16(state_in[16+:16] & 16'hB7ED);
			state_out[24+:4] = nibble_red16(state_in[16+:16] & 16'hDB7E);
			state_out[28+:4] = nibble_red16(state_in[16+:16] & 16'hEDB7);
			if (DataWidth == 64) begin
				state_out[32+:4] = nibble_red16(state_in[32+:16] & 16'h7EDB);
				state_out[36+:4] = nibble_red16(state_in[32+:16] & 16'hB7ED);
				state_out[40+:4] = nibble_red16(state_in[32+:16] & 16'hDB7E);
				state_out[44+:4] = nibble_red16(state_in[32+:16] & 16'hEDB7);
				state_out[48+:4] = nibble_red16(state_in[48+:16] & 16'hEDB7);
				state_out[52+:4] = nibble_red16(state_in[48+:16] & 16'h7EDB);
				state_out[56+:4] = nibble_red16(state_in[48+:16] & 16'hB7ED);
				state_out[60+:4] = nibble_red16(state_in[48+:16] & 16'hDB7E);
			end
			mult_prime_layer = state_out;
		end
	endfunction
	reg [DataWidth - 1:0] data_state;
	reg [DataWidth - 1:0] k0;
	reg [DataWidth - 1:0] k0_prime;
	reg [DataWidth - 1:0] k1;
	always @(*) begin : p_prince
		k0 = key_i[DataWidth - 1:0];
		k0_prime = {k0[0], k0[DataWidth - 1:2], k0[DataWidth - 1] ^ k0[1]};
		k1 = key_i[(2 * DataWidth) - 1:DataWidth];
		if (dec_i) begin
			k0 = k0_prime;
			k0_prime = key_i[DataWidth - 1:0];
			k1 = k1 ^ AlphaConst[DataWidth - 1:0];
		end
		data_state = data_i ^ k0;
		data_state = data_state ^ k1;
		data_state = data_state ^ RoundConst[((DataWidth - 1) >= 0 ? DataWidth - 1 : ((DataWidth - 1) + ((DataWidth - 1) >= 0 ? DataWidth : 2 - DataWidth)) - 1)-:((DataWidth - 1) >= 0 ? DataWidth : 2 - DataWidth)];
		begin : sv2v_autoblock_153
			reg signed [31:0] k;
			for (k = 1; k <= NumRoundsHalf; k = k + 1)
				begin
					data_state = sbox4_layer(data_state);
					data_state = mult_prime_layer(data_state);
					data_state = shiftrows_layer(data_state);
					data_state = data_state ^ RoundConst[(k * 64) + ((DataWidth - 1) >= 0 ? DataWidth - 1 : ((DataWidth - 1) + ((DataWidth - 1) >= 0 ? DataWidth : 2 - DataWidth)) - 1)-:((DataWidth - 1) >= 0 ? DataWidth : 2 - DataWidth)];
					data_state = data_state ^ k1;
				end
		end
		data_state = sbox4_layer(data_state);
		data_state = mult_prime_layer(data_state);
		data_state = sbox4_inv_layer(data_state);
		begin : sv2v_autoblock_154
			reg signed [31:0] k;
			for (k = 11 - NumRoundsHalf; k <= 10; k = k + 1)
				begin
					data_state = data_state ^ k1;
					data_state = data_state ^ RoundConst[(k * 64) + ((DataWidth - 1) >= 0 ? DataWidth - 1 : ((DataWidth - 1) + ((DataWidth - 1) >= 0 ? DataWidth : 2 - DataWidth)) - 1)-:((DataWidth - 1) >= 0 ? DataWidth : 2 - DataWidth)];
					data_state = shiftrows_inv_layer(data_state);
					data_state = mult_prime_layer(data_state);
					data_state = sbox4_inv_layer(data_state);
				end
		end
		data_state = data_state ^ RoundConst[704 + ((DataWidth - 1) >= 0 ? DataWidth - 1 : ((DataWidth - 1) + ((DataWidth - 1) >= 0 ? DataWidth : 2 - DataWidth)) - 1)-:((DataWidth - 1) >= 0 ? DataWidth : 2 - DataWidth)];
		data_state = data_state ^ k1;
		data_o = data_state ^ k0_prime;
	end
endmodule
