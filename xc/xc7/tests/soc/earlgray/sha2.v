module sha2 (
	clk_i,
	rst_ni,
	wipe_secret,
	wipe_v,
	fifo_rvalid,
	fifo_rdata,
	fifo_rready,
	sha_en,
	hash_start,
	hash_process,
	hash_done,
	message_length,
	digest
);
	localparam [1:0] FifoIdle = 0;
	localparam [1:0] ShaIdle = 0;
	localparam [1:0] FifoLoadFromFifo = 1;
	localparam [1:0] ShaCompress = 1;
	localparam [1:0] FifoWait = 2;
	localparam [1:0] ShaUpdateDigest = 2;
	localparam signed [31:0] NumAlerts = 1;
	localparam [NumAlerts - 1:0] AlertAsyncOn = sv2v_cast_1(1'b1);
	localparam signed [31:0] MsgFifoDepth = 16;
	localparam signed [31:0] NumRound = 64;
	localparam signed [31:0] WordByte = 4;
	localparam [255:0] InitHash = {32'h 6a09_e667, 32'h bb67_ae85, 32'h 3c6e_f372, 32'h a54f_f53a, 32'h 510e_527f, 32'h 9b05_688c, 32'h 1f83_d9ab, 32'h 5be0_cd19};
	localparam [2047:0] CubicRootPrime = {32'h 428a_2f98, 32'h 7137_4491, 32'h b5c0_fbcf, 32'h e9b5_dba5, 32'h 3956_c25b, 32'h 59f1_11f1, 32'h 923f_82a4, 32'h ab1c_5ed5, 32'h d807_aa98, 32'h 1283_5b01, 32'h 2431_85be, 32'h 550c_7dc3, 32'h 72be_5d74, 32'h 80de_b1fe, 32'h 9bdc_06a7, 32'h c19b_f174, 32'h e49b_69c1, 32'h efbe_4786, 32'h 0fc1_9dc6, 32'h 240c_a1cc, 32'h 2de9_2c6f, 32'h 4a74_84aa, 32'h 5cb0_a9dc, 32'h 76f9_88da, 32'h 983e_5152, 32'h a831_c66d, 32'h b003_27c8, 32'h bf59_7fc7, 32'h c6e0_0bf3, 32'h d5a7_9147, 32'h 06ca_6351, 32'h 1429_2967, 32'h 27b7_0a85, 32'h 2e1b_2138, 32'h 4d2c_6dfc, 32'h 5338_0d13, 32'h 650a_7354, 32'h 766a_0abb, 32'h 81c2_c92e, 32'h 9272_2c85, 32'h a2bf_e8a1, 32'h a81a_664b, 32'h c24b_8b70, 32'h c76c_51a3, 32'h d192_e819, 32'h d699_0624, 32'h f40e_3585, 32'h 106a_a070, 32'h 19a4_c116, 32'h 1e37_6c08, 32'h 2748_774c, 32'h 34b0_bcb5, 32'h 391c_0cb3, 32'h 4ed8_aa4a, 32'h 5b9c_ca4f, 32'h 682e_6ff3, 32'h 748f_82ee, 32'h 78a5_636f, 32'h 84c8_7814, 32'h 8cc7_0208, 32'h 90be_fffa, 32'h a450_6ceb, 32'h bef9_a3f7, 32'h c671_78f2};
	function automatic [31:0] conv_endian;
		input reg [31:0] v;
		input reg swap;
		reg [31:0] conv_data;
		begin
			begin : sv2v_autoblock_7
				reg [31:0] _sv2v_strm_2F008_inp;
				reg [31:0] _sv2v_strm_2F008_out;
				integer _sv2v_strm_2F008_idx;
				integer _sv2v_strm_2F008_bas;
				_sv2v_strm_2F008_inp = v;
				for (_sv2v_strm_2F008_idx = 0; _sv2v_strm_2F008_idx <= 23; _sv2v_strm_2F008_idx = _sv2v_strm_2F008_idx + 8)
					_sv2v_strm_2F008_out[31 - _sv2v_strm_2F008_idx-:8] = _sv2v_strm_2F008_inp[_sv2v_strm_2F008_idx+:8];
				_sv2v_strm_2F008_bas = _sv2v_strm_2F008_idx;
				for (_sv2v_strm_2F008_idx = 0; _sv2v_strm_2F008_idx < (32 - _sv2v_strm_2F008_bas); _sv2v_strm_2F008_idx = _sv2v_strm_2F008_idx + 1)
					_sv2v_strm_2F008_out[_sv2v_strm_2F008_idx] = _sv2v_strm_2F008_inp[_sv2v_strm_2F008_idx + _sv2v_strm_2F008_bas];
				conv_data = _sv2v_strm_2F008_out;
			end
			conv_endian = (swap ? conv_data : v);
		end
	endfunction
	function automatic [31:0] rotr;
		input reg [31:0] v;
		input reg signed [31:0] amt;
		rotr = (v >> amt) | (v << (32 - amt));
	endfunction
	function automatic [31:0] shiftr;
		input reg [31:0] v;
		input reg signed [31:0] amt;
		shiftr = v >> amt;
	endfunction
	function automatic [255:0] compress;
		input reg [31:0] w;
		input reg [31:0] k;
		input reg [255:0] h_i;
		reg [31:0] sigma_0;
		reg [31:0] sigma_1;
		reg [31:0] ch;
		reg [31:0] maj;
		reg [31:0] temp1;
		reg [31:0] temp2;
		begin
			sigma_1 = (rotr(h_i[128+:32], 6) ^ rotr(h_i[128+:32], 11)) ^ rotr(h_i[128+:32], 25);
			ch = (h_i[128+:32] & h_i[160+:32]) ^ (~h_i[128+:32] & h_i[192+:32]);
			temp1 = (((h_i[224+:32] + sigma_1) + ch) + k) + w;
			sigma_0 = (rotr(h_i[0+:32], 2) ^ rotr(h_i[0+:32], 13)) ^ rotr(h_i[0+:32], 22);
			maj = ((h_i[0+:32] & h_i[32+:32]) ^ (h_i[0+:32] & h_i[64+:32])) ^ (h_i[32+:32] & h_i[64+:32]);
			temp2 = sigma_0 + maj;
			compress[224+:32] = h_i[192+:32];
			compress[192+:32] = h_i[160+:32];
			compress[160+:32] = h_i[128+:32];
			compress[128+:32] = h_i[96+:32] + temp1;
			compress[96+:32] = h_i[64+:32];
			compress[64+:32] = h_i[32+:32];
			compress[32+:32] = h_i[0+:32];
			compress[0+:32] = temp1 + temp2;
		end
	endfunction
	function automatic [31:0] calc_w;
		input reg [31:0] w_0;
		input reg [31:0] w_1;
		input reg [31:0] w_9;
		input reg [31:0] w_14;
		reg [31:0] sum0;
		reg [31:0] sum1;
		begin
			sum0 = (rotr(w_1, 7) ^ rotr(w_1, 18)) ^ shiftr(w_1, 3);
			sum1 = (rotr(w_14, 17) ^ rotr(w_14, 19)) ^ shiftr(w_14, 10);
			calc_w = ((w_0 + sum0) + w_9) + sum1;
		end
	endfunction
	localparam [31:0] NoError = 32'h 0000_0000;
	localparam [31:0] SwPushMsgWhenShaDisabled = 32'h 0000_0001;
	localparam [31:0] SwHashStartWhenShaDisabled = 32'h 0000_0002;
	localparam [31:0] SwUpdateSecretKeyInProcess = 32'h 0000_0003;
	localparam [31:0] SwHashStartWhenActive = 32'h 0000_0004;
	input clk_i;
	input rst_ni;
	input wipe_secret;
	input wire [31:0] wipe_v;
	input fifo_rvalid;
	input wire [(32 + WordByte) - 1:0] fifo_rdata;
	output wire fifo_rready;
	input sha_en;
	input hash_start;
	input hash_process;
	output reg hash_done;
	input [63:0] message_length;
	output reg [255:0] digest;
	wire msg_feed_complete;
	wire shaf_rready;
	wire [31:0] shaf_rdata;
	wire shaf_rvalid;
	reg [5:0] round;
	reg [3:0] w_index;
	reg [511:0] w;
	reg update_w_from_fifo;
	reg calculate_next_w;
	reg init_hash;
	reg run_hash;
	wire complete_one_chunk;
	reg update_digest;
	wire clear_digest;
	reg hash_done_next;
	reg [255:0] hash;
	always @(posedge clk_i or negedge rst_ni) begin : fill_w
		if (!rst_ni)
			w <= 1'sb0;
		else if (wipe_secret)
			w <= w ^ {16 {wipe_v}};
		else if (!sha_en)
			w <= 1'sb0;
		else if (!run_hash && update_w_from_fifo)
			w <= {shaf_rdata, w[32+:480]};
		else if (calculate_next_w)
			w <= {calc_w(w[0+:32], w[32+:32], w[288+:32], w[448+:32]), w[32+:480]};
		else if (run_hash)
			w <= {32'd0, w[32+:480]};
	end
	always @(posedge clk_i or negedge rst_ni) begin : compress_round
		if (!rst_ni)
			hash <= {8 {1'sb0}};
		else if (wipe_secret) begin : sv2v_autoblock_148
			reg signed [31:0] i;
			for (i = 0; i < 8; i = i + 1)
				hash[i * 32+:32] <= hash[i * 32+:32] ^ wipe_v;
		end
		else if (init_hash)
			hash <= digest;
		else if (run_hash)
			hash <= compress(w[0+:32], CubicRootPrime[(63 - round) * 32+:32], hash);
	end
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			digest <= {8 {1'sb0}};
		else if (wipe_secret) begin : sv2v_autoblock_149
			reg signed [31:0] i;
			for (i = 0; i < 8; i = i + 1)
				digest[i * 32+:32] <= digest[i * 32+:32] ^ wipe_v;
		end
		else if (hash_start) begin : sv2v_autoblock_150
			reg signed [31:0] i;
			for (i = 0; i < 8; i = i + 1)
				digest[i * 32+:32] <= InitHash[(7 - i) * 32+:32];
		end
		else if (!sha_en || clear_digest)
			digest <= 1'sb0;
		else if (update_digest) begin : sv2v_autoblock_151
			reg signed [31:0] i;
			for (i = 0; i < 8; i = i + 1)
				digest[i * 32+:32] <= digest[i * 32+:32] + hash[i * 32+:32];
		end
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			round <= 1'sb0;
		else if (!sha_en)
			round <= 1'sb0;
		else if (run_hash)
			if (round == (NumRound - 1))
				round <= 1'sb0;
			else
				round <= round + 1;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			w_index <= 1'sb0;
		else if (!sha_en)
			w_index <= 1'sb0;
		else if (update_w_from_fifo)
			w_index <= w_index + 1;
	assign shaf_rready = update_w_from_fifo;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			hash_done <= 1'b0;
		else
			hash_done <= hash_done_next;
	reg [1:0] fifo_st_q;
	reg [1:0] fifo_st_d;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			fifo_st_q <= FifoIdle;
		else
			fifo_st_q <= fifo_st_d;
	always @(*) begin
		fifo_st_d = FifoIdle;
		update_w_from_fifo = 1'b0;
		hash_done_next = 1'b0;
		case (fifo_st_q)
			FifoIdle:
				if (hash_start)
					fifo_st_d = FifoLoadFromFifo;
				else
					fifo_st_d = FifoIdle;
			FifoLoadFromFifo:
				if (!sha_en) begin
					fifo_st_d = FifoIdle;
					update_w_from_fifo = 1'b0;
				end
				else if (!shaf_rvalid) begin
					fifo_st_d = FifoLoadFromFifo;
					update_w_from_fifo = 1'b0;
				end
				else if (w_index == 4'd 15) begin
					fifo_st_d = FifoWait;
					update_w_from_fifo = 1'b1;
				end
				else begin
					fifo_st_d = FifoLoadFromFifo;
					update_w_from_fifo = 1'b1;
				end
			FifoWait:
				if (msg_feed_complete && complete_one_chunk) begin
					fifo_st_d = FifoIdle;
					hash_done_next = 1'b1;
				end
				else if (complete_one_chunk)
					fifo_st_d = FifoLoadFromFifo;
				else
					fifo_st_d = FifoWait;
			default: fifo_st_d = FifoIdle;
		endcase
	end
	reg [1:0] sha_st_q;
	reg [1:0] sha_st_d;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			sha_st_q <= ShaIdle;
		else
			sha_st_q <= sha_st_d;
	assign clear_digest = hash_start;
	always @(*) begin
		update_digest = 1'b0;
		calculate_next_w = 1'b0;
		init_hash = 1'b0;
		run_hash = 1'b0;
		case (sha_st_q)
			ShaIdle:
				if (fifo_st_q == FifoWait) begin
					init_hash = 1'b1;
					sha_st_d = ShaCompress;
				end
				else
					sha_st_d = ShaIdle;
			ShaCompress: begin
				run_hash = 1'b1;
				if (round < 48)
					calculate_next_w = 1'b1;
				if (complete_one_chunk)
					sha_st_d = ShaUpdateDigest;
				else
					sha_st_d = ShaCompress;
			end
			ShaUpdateDigest: begin
				update_digest = 1'b1;
				if (fifo_st_q == FifoWait) begin
					init_hash = 1'b1;
					sha_st_d = ShaCompress;
				end
				else
					sha_st_d = ShaIdle;
			end
			default: sha_st_d = ShaIdle;
		endcase
	end
	assign complete_one_chunk = round == 6'd63;
	sha2_pad u_pad(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.wipe_secret(wipe_secret),
		.wipe_v(wipe_v),
		.fifo_rvalid(fifo_rvalid),
		.fifo_rdata(fifo_rdata),
		.fifo_rready(fifo_rready),
		.shaf_rvalid(shaf_rvalid),
		.shaf_rdata(shaf_rdata),
		.shaf_rready(shaf_rready),
		.sha_en(sha_en),
		.hash_start(hash_start),
		.hash_process(hash_process),
		.hash_done(hash_done),
		.message_length(message_length),
		.msg_feed_complete(msg_feed_complete)
	);
	function automatic [0:0] sv2v_cast_1;
		input reg [0:0] inp;
		sv2v_cast_1 = inp;
	endfunction
endmodule
