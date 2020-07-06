module aes_sbox (
	op_i,
	data_i,
	data_o
);
	parameter SBoxImpl = "lut";
	input wire [0:0] op_i;
	input wire [7:0] data_i;
	output wire [7:0] data_o;
	generate
		if (SBoxImpl == "lut") begin : gen_sbox_lut
			aes_sbox_lut aes_sbox(
				.op_i(op_i),
				.data_i(data_i),
				.data_o(data_o)
			);
		end
		else if (SBoxImpl == "canright") begin : gen_sbox_canright
			aes_sbox_canright aes_sbox(
				.op_i(op_i),
				.data_i(data_i),
				.data_o(data_o)
			);
		end
	endgenerate
endmodule
