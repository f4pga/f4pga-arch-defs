module aes_control (
	clk_i,
	rst_ni,
	cipher_op_i,
	manual_operation_i,
	start_i,
	key_clear_i,
	data_in_clear_i,
	data_out_clear_i,
	data_in_qe_i,
	key_init_qe_i,
	data_out_re_i,
	data_in_we_o,
	data_out_we_o,
	cipher_in_valid_o,
	cipher_in_ready_i,
	cipher_out_valid_i,
	cipher_out_ready_o,
	cipher_start_o,
	cipher_dec_key_gen_o,
	cipher_dec_key_gen_i,
	cipher_key_clear_o,
	cipher_key_clear_i,
	cipher_data_out_clear_o,
	cipher_data_out_clear_i,
	key_init_sel_o,
	key_init_we_o,
	start_o,
	start_we_o,
	key_clear_o,
	key_clear_we_o,
	data_in_clear_o,
	data_in_clear_we_o,
	data_out_clear_o,
	data_out_clear_we_o,
	output_valid_o,
	output_valid_we_o,
	input_ready_o,
	input_ready_we_o,
	idle_o,
	idle_we_o,
	stall_o,
	stall_we_o
);
	localparam [1:0] IDLE = 0;
	localparam [1:0] LOAD = 1;
	localparam [1:0] FINISH = 2;
	localparam [1:0] CLEAR = 3;
	input wire clk_i;
	input wire rst_ni;
	input wire [0:0] cipher_op_i;
	input wire manual_operation_i;
	input wire start_i;
	input wire key_clear_i;
	input wire data_in_clear_i;
	input wire data_out_clear_i;
	input wire [3:0] data_in_qe_i;
	input wire [7:0] key_init_qe_i;
	input wire [3:0] data_out_re_i;
	output reg data_in_we_o;
	output reg data_out_we_o;
	output reg cipher_in_valid_o;
	input wire cipher_in_ready_i;
	input wire cipher_out_valid_i;
	output reg cipher_out_ready_o;
	output reg cipher_start_o;
	output reg cipher_dec_key_gen_o;
	input wire cipher_dec_key_gen_i;
	output reg cipher_key_clear_o;
	input wire cipher_key_clear_i;
	output reg cipher_data_out_clear_o;
	input wire cipher_data_out_clear_i;
	output reg [0:0] key_init_sel_o;
	output reg [7:0] key_init_we_o;
	output wire start_o;
	output reg start_we_o;
	output wire key_clear_o;
	output reg key_clear_we_o;
	output wire data_in_clear_o;
	output reg data_in_clear_we_o;
	output wire data_out_clear_o;
	output reg data_out_clear_we_o;
	output wire output_valid_o;
	output wire output_valid_we_o;
	output wire input_ready_o;
	output wire input_ready_we_o;
	output reg idle_o;
	output reg idle_we_o;
	output reg stall_o;
	output reg stall_we_o;
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
			begin : sv2v_autoblock_150
				reg signed [31:0] j;
				for (j = 0; j < 4; j = j + 1)
					begin : sv2v_autoblock_151
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
		begin : sv2v_autoblock_152
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
			begin : sv2v_autoblock_153
				reg signed [31:0] i;
				for (i = 0; i < 8; i = i + 1)
					begin : sv2v_autoblock_154
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
	reg [1:0] aes_ctrl_ns;
	reg [1:0] aes_ctrl_cs;
	wire [3:0] data_in_new_d;
	reg [3:0] data_in_new_q;
	wire data_in_new;
	reg data_in_load;
	wire key_init_clear;
	wire [7:0] key_init_new_d;
	reg [7:0] key_init_new_q;
	wire key_init_new;
	reg dec_key_gen;
	wire [3:0] data_out_read_d;
	reg [3:0] data_out_read_q;
	wire data_out_read;
	reg output_valid_q;
	wire start;
	wire finish;
	assign start = (manual_operation_i ? start_i : data_in_new);
	assign finish = (manual_operation_i ? 1'b1 : ~output_valid_q | data_out_read);
	always @(*) begin : aes_ctrl_fsm
		cipher_in_valid_o = 1'b0;
		cipher_out_ready_o = 1'b0;
		cipher_start_o = 1'b0;
		cipher_dec_key_gen_o = 1'b0;
		cipher_key_clear_o = 1'b0;
		cipher_data_out_clear_o = 1'b0;
		key_init_sel_o = KEY_INIT_INPUT;
		key_init_we_o = 8'h00;
		start_we_o = 1'b0;
		key_clear_we_o = 1'b0;
		data_in_clear_we_o = 1'b0;
		data_out_clear_we_o = 1'b0;
		idle_o = 1'b0;
		idle_we_o = 1'b0;
		stall_o = 1'b0;
		stall_we_o = 1'b0;
		dec_key_gen = 1'b0;
		data_in_load = 1'b0;
		data_in_we_o = 1'b0;
		data_out_we_o = 1'b0;
		aes_ctrl_ns = aes_ctrl_cs;
		case (aes_ctrl_cs)
			IDLE: begin
				idle_o = 1'b1;
				idle_we_o = 1'b1;
				stall_o = 1'b0;
				stall_we_o = 1'b1;
				if (start) begin
					cipher_start_o = 1'b1;
					cipher_dec_key_gen_o = key_init_new & (cipher_op_i == CIPH_INV);
					cipher_in_valid_o = 1'b1;
					if (cipher_in_ready_i) begin
						idle_o = 1'b0;
						idle_we_o = 1'b1;
						start_we_o = ~cipher_dec_key_gen_o;
						aes_ctrl_ns = LOAD;
					end
				end
				else if (key_clear_i || data_out_clear_i) begin
					cipher_key_clear_o = key_clear_i;
					cipher_data_out_clear_o = data_out_clear_i;
					cipher_in_valid_o = 1'b1;
					if (cipher_in_ready_i) begin
						idle_o = 1'b0;
						idle_we_o = 1'b1;
						aes_ctrl_ns = CLEAR;
					end
				end
				else if (data_in_clear_i) begin
					idle_o = 1'b0;
					idle_we_o = 1'b1;
					aes_ctrl_ns = CLEAR;
				end
				key_init_we_o = (idle_o ? key_init_qe_i : 8'h00);
			end
			LOAD: begin
				data_in_load = ~cipher_dec_key_gen_i;
				dec_key_gen = cipher_dec_key_gen_i;
				aes_ctrl_ns = FINISH;
			end
			FINISH:
				if (cipher_dec_key_gen_i) begin
					cipher_out_ready_o = 1'b1;
					if (cipher_out_valid_i)
						aes_ctrl_ns = IDLE;
				end
				else begin
					stall_o = !finish & cipher_out_valid_i;
					stall_we_o = 1'b1;
					cipher_out_ready_o = finish;
					if (finish & cipher_out_valid_i) begin
						data_out_we_o = 1'b1;
						aes_ctrl_ns = IDLE;
					end
				end
			CLEAR: begin
				if (data_in_clear_i) begin
					data_in_we_o = 1'b1;
					data_in_clear_we_o = 1'b1;
				end
				if (cipher_key_clear_i || cipher_data_out_clear_i) begin
					cipher_out_ready_o = 1'b1;
					if (cipher_out_valid_i) begin
						if (cipher_key_clear_i) begin
							key_init_sel_o = KEY_INIT_CLEAR;
							key_init_we_o = 8'hFF;
							key_clear_we_o = 1'b1;
						end
						if (cipher_data_out_clear_i) begin
							data_out_we_o = 1'b1;
							data_out_clear_we_o = 1'b1;
						end
						aes_ctrl_ns = IDLE;
					end
				end
				else
					aes_ctrl_ns = IDLE;
			end
			default: aes_ctrl_ns = IDLE;
		endcase
	end
	always @(posedge clk_i or negedge rst_ni) begin : reg_fsm
		if (!rst_ni)
			aes_ctrl_cs <= IDLE;
		else
			aes_ctrl_cs <= aes_ctrl_ns;
	end
	assign key_init_clear = (key_init_sel_o == KEY_INIT_CLEAR) & &key_init_we_o;
	assign key_init_new_d = (dec_key_gen | key_init_clear ? 1'sb0 : key_init_new_q | key_init_qe_i);
	assign key_init_new = &key_init_new_d;
	assign data_in_new_d = (data_in_load | data_in_we_o ? 1'sb0 : data_in_new_q | data_in_qe_i);
	assign data_in_new = &data_in_new_d;
	assign data_out_read_d = (&data_out_read_q ? 1'sb0 : data_out_read_q | data_out_re_i);
	assign data_out_read = &data_out_read_d;
	always @(posedge clk_i or negedge rst_ni) begin : reg_edge_detection
		if (!rst_ni) begin
			key_init_new_q <= 1'sb0;
			data_in_new_q <= 1'sb0;
			data_out_read_q <= 1'sb0;
		end
		else begin
			key_init_new_q <= key_init_new_d;
			data_in_new_q <= data_in_new_d;
			data_out_read_q <= data_out_read_d;
		end
	end
	assign output_valid_o = data_out_we_o & ~data_out_clear_we_o;
	assign output_valid_we_o = (data_out_we_o | data_out_read) | data_out_clear_we_o;
	always @(posedge clk_i or negedge rst_ni) begin : reg_output_valid
		if (!rst_ni)
			output_valid_q <= 1'sb0;
		else if (output_valid_we_o)
			output_valid_q <= output_valid_o;
	end
	assign input_ready_o = ~data_in_new;
	assign input_ready_we_o = (data_in_new | data_in_load) | data_in_we_o;
	assign start_o = 1'b0;
	assign key_clear_o = 1'b0;
	assign data_in_clear_o = 1'b0;
	assign data_out_clear_o = 1'b0;
endmodule
