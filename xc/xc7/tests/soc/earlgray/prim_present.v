module prim_present (
	data_i,
	key_i,
	data_o
);
	parameter signed [31:0] DataWidth = 64;
	parameter signed [31:0] KeyWidth = 80;
	parameter signed [31:0] NumRounds = 31;
	input [DataWidth - 1:0] data_i;
	input [KeyWidth - 1:0] key_i;
	output reg [DataWidth - 1:0] data_o;
	localparam [63:0] SBox4 = {4'h2, 4'h1, 4'h7, 4'h4, 4'h8, 4'hF, 4'hE, 4'h3, 4'hD, 4'hA, 4'h0, 4'h9, 4'hB, 4'h6, 4'h5, 4'hC};
	localparam [159:0] Perm32 = {5'd31, 5'd23, 5'd15, 5'd7, 5'd30, 5'd22, 5'd14, 5'd6, 5'd29, 5'd21, 5'd13, 5'd5, 5'd28, 5'd20, 5'd12, 5'd4, 5'd27, 5'd19, 5'd11, 5'd3, 5'd26, 5'd18, 5'd10, 5'd2, 5'd25, 5'd17, 5'd9, 5'd1, 5'd24, 5'd16, 5'd8, 5'd0};
	localparam [383:0] Perm64 = {6'd63, 6'd47, 6'd31, 6'd15, 6'd62, 6'd46, 6'd30, 6'd14, 6'd61, 6'd45, 6'd29, 6'd13, 6'd60, 6'd44, 6'd28, 6'd12, 6'd59, 6'd43, 6'd27, 6'd11, 6'd58, 6'd42, 6'd26, 6'd10, 6'd57, 6'd41, 6'd25, 6'd09, 6'd56, 6'd40, 6'd24, 6'd08, 6'd55, 6'd39, 6'd23, 6'd07, 6'd54, 6'd38, 6'd22, 6'd06, 6'd53, 6'd37, 6'd21, 6'd05, 6'd52, 6'd36, 6'd20, 6'd04, 6'd51, 6'd35, 6'd19, 6'd03, 6'd50, 6'd34, 6'd18, 6'd02, 6'd49, 6'd33, 6'd17, 6'd01, 6'd48, 6'd32, 6'd16, 6'd00};
	function automatic [DataWidth - 1:0] sbox4_layer;
		input reg [DataWidth - 1:0] state_in;
		reg [63:0] state_out;
		begin
			begin : sv2v_autoblock_147
				reg signed [31:0] k;
				for (k = 0; k < (DataWidth / 4); k = k + 1)
					state_out[k * 4+:4] = SBox4[state_in[k * 4+:4] * 4+:4];
			end
			sbox4_layer = state_out;
		end
	endfunction
	function automatic [DataWidth - 1:0] perm_layer;
		input reg [DataWidth - 1:0] state_in;
		reg [DataWidth - 1:0] state_out;
		begin
			if (DataWidth == 64) begin : sv2v_autoblock_148
				reg signed [31:0] k;
				for (k = 0; k < DataWidth; k = k + 1)
					state_out[k] = state_in[Perm64[k * 6+:6]];
			end
			else begin : sv2v_autoblock_149
				reg signed [31:0] k;
				for (k = 0; k < DataWidth; k = k + 1)
					state_out[k] = state_in[Perm32[k * 5+:5]];
			end
			perm_layer = state_out;
		end
	endfunction
	function automatic [KeyWidth - 1:0] update_key;
		input reg [KeyWidth - 1:0] key_in;
		input reg [4:0] round_cnt;
		reg [KeyWidth - 1:0] key_out;
		begin
			key_out = sv2v_cast_50F6E(key_in << 61) | sv2v_cast_50F6E(key_in >> (KeyWidth - 61));
			key_out[KeyWidth - 1-:4] = SBox4[key_out[KeyWidth - 1-:4] * 4+:4];
			key_out[19:15] = key_out[19:15] ^ round_cnt;
			update_key = key_out;
		end
	endfunction
	reg [DataWidth - 1:0] data_state;
	reg [KeyWidth - 1:0] round_key;
	always @(*) begin : p_present
		data_state = data_i;
		round_key = key_i;
		begin : sv2v_autoblock_150
			reg signed [31:0] k;
			for (k = 0; k < NumRounds; k = k + 1)
				begin
					data_state = data_state ^ round_key[KeyWidth - 1:KeyWidth - DataWidth];
					data_state = sbox4_layer(data_state);
					data_state = perm_layer(data_state);
					round_key = update_key(round_key, sv2v_cast_5_signed(k + 1));
				end
		end
		data_o = data_state ^ round_key;
	end
	function automatic [KeyWidth - 1:0] sv2v_cast_50F6E;
		input reg [KeyWidth - 1:0] inp;
		sv2v_cast_50F6E = inp;
	endfunction
	function automatic signed [4:0] sv2v_cast_5_signed;
		input reg signed [4:0] inp;
		sv2v_cast_5_signed = inp;
	endfunction
endmodule
