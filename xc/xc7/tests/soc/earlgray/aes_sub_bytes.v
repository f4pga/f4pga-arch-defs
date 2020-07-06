module aes_sub_bytes (
	op_i,
	data_i,
	data_o
);
	parameter SBoxImpl = "lut";
	input wire [0:0] op_i;
	input wire [127:0] data_i;
	output wire [127:0] data_o;
	generate
		genvar i;
		genvar j;
		for (j = 0; j < 4; j = j + 1) begin : gen_sbox_j
			for (i = 0; i < 4; i = i + 1) begin : gen_sbox_i
				aes_sbox #(.SBoxImpl(SBoxImpl)) aes_sbox_ij(
					.op_i(op_i),
					.data_i(data_i[((i * 4) + j) * 8+:8]),
					.data_o(data_o[((i * 4) + j) * 8+:8])
				);
			end
		end
	endgenerate
endmodule
