module sha2_pad (
	clk_i,
	rst_ni,
	wipe_secret,
	wipe_v,
	fifo_rvalid,
	fifo_rdata,
	fifo_rready,
	shaf_rvalid,
	shaf_rdata,
	shaf_rready,
	sha_en,
	hash_start,
	hash_process,
	hash_done,
	message_length,
	msg_feed_complete
);
	localparam [2:0] FifoIn = 0;
	localparam [2:0] StIdle = 0;
	localparam [2:0] Pad80 = 1;
	localparam [2:0] StFifoReceive = 1;
	localparam [2:0] Pad00 = 2;
	localparam [2:0] StPad80 = 2;
	localparam [2:0] LenHi = 3;
	localparam [2:0] StPad00 = 3;
	localparam [2:0] LenLo = 4;
	localparam [2:0] StLenHi = 4;
	localparam [2:0] StLenLo = 5;
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
			begin : sv2v_autoblock_1
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
	output reg fifo_rready;
	output reg shaf_rvalid;
	output reg [31:0] shaf_rdata;
	input shaf_rready;
	input sha_en;
	input hash_start;
	input hash_process;
	input hash_done;
	input [63:0] message_length;
	output wire msg_feed_complete;
	reg [63:0] tx_count;
	reg inc_txcount;
	wire fifo_partial;
	wire txcnt_eq_1a0;
	reg hash_process_flag;
	assign fifo_partial = ~&fifo_rdata[WordByte + -1-:WordByte];
	assign txcnt_eq_1a0 = tx_count[8:0] == 9'h1a0;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			hash_process_flag <= 1'b0;
		else if (hash_process)
			hash_process_flag <= 1'b1;
		else if (hash_done || hash_start)
			hash_process_flag <= 1'b0;
	reg [2:0] sel_data;
	always @(*)
		case (sel_data)
			FifoIn: shaf_rdata = fifo_rdata[32 + (WordByte + -1)-:((32 + (WordByte + -1)) - WordByte) + 1];
			Pad80:
				case (message_length[4:3])
					2'b 00: shaf_rdata = 32'h 8000_0000;
					2'b 01: shaf_rdata = {fifo_rdata[32 + (WordByte + -1):(32 + (WordByte + -1)) - 7], 24'h 8000_00};
					2'b 10: shaf_rdata = {fifo_rdata[32 + (WordByte + -1):(32 + (WordByte + -1)) - 15], 16'h 8000};
					2'b 11: shaf_rdata = {fifo_rdata[32 + (WordByte + -1):(32 + (WordByte + -1)) - 23], 8'h 80};
					default: shaf_rdata = 32'h0;
				endcase
			Pad00: shaf_rdata = 1'sb0;
			LenHi: shaf_rdata = message_length[63:32];
			LenLo: shaf_rdata = message_length[31:0];
			default: shaf_rdata = 1'sb0;
		endcase
	reg [2:0] st_q;
	reg [2:0] st_d;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			st_q <= StIdle;
		else
			st_q <= st_d;
	always @(*) begin
		shaf_rvalid = 1'b0;
		inc_txcount = 1'b0;
		sel_data = FifoIn;
		fifo_rready = 1'b0;
		st_d = StIdle;
		case (st_q)
			StIdle: begin
				sel_data = FifoIn;
				shaf_rvalid = 1'b0;
				if (sha_en && hash_start) begin
					inc_txcount = 1'b0;
					st_d = StFifoReceive;
				end
				else
					st_d = StIdle;
			end
			StFifoReceive: begin
				sel_data = FifoIn;
				if (fifo_partial && fifo_rvalid) begin
					shaf_rvalid = 1'b0;
					inc_txcount = 1'b0;
					fifo_rready = 1'b0;
					st_d = StPad80;
				end
				else if (!hash_process_flag) begin
					fifo_rready = shaf_rready;
					shaf_rvalid = fifo_rvalid;
					inc_txcount = shaf_rready;
					st_d = StFifoReceive;
				end
				else if (tx_count == message_length) begin
					shaf_rvalid = 1'b0;
					inc_txcount = 1'b0;
					fifo_rready = 1'b0;
					st_d = StPad80;
				end
				else begin
					shaf_rvalid = fifo_rvalid;
					fifo_rready = shaf_rready;
					inc_txcount = shaf_rready;
					st_d = StFifoReceive;
				end
			end
			StPad80: begin
				sel_data = Pad80;
				shaf_rvalid = 1'b1;
				fifo_rready = shaf_rready && |message_length[4:3];
				if (shaf_rready && txcnt_eq_1a0) begin
					st_d = StLenHi;
					inc_txcount = 1'b1;
				end
				else if (shaf_rready && !txcnt_eq_1a0) begin
					st_d = StPad00;
					inc_txcount = 1'b1;
				end
				else begin
					st_d = StPad80;
					inc_txcount = 1'b0;
				end
			end
			StPad00: begin
				sel_data = Pad00;
				shaf_rvalid = 1'b1;
				if (shaf_rready) begin
					inc_txcount = 1'b1;
					if (txcnt_eq_1a0)
						st_d = StLenHi;
					else
						st_d = StPad00;
				end
				else
					st_d = StPad00;
			end
			StLenHi: begin
				sel_data = LenHi;
				shaf_rvalid = 1'b1;
				if (shaf_rready) begin
					st_d = StLenLo;
					inc_txcount = 1'b1;
				end
				else begin
					st_d = StLenHi;
					inc_txcount = 1'b0;
				end
			end
			StLenLo: begin
				sel_data = LenLo;
				shaf_rvalid = 1'b1;
				if (shaf_rready) begin
					st_d = StIdle;
					inc_txcount = 1'b1;
				end
				else begin
					st_d = StLenLo;
					inc_txcount = 1'b0;
				end
			end
			default: st_d = StIdle;
		endcase
	end
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			tx_count <= 1'sb0;
		else if (hash_start)
			tx_count <= 1'sb0;
		else if (inc_txcount)
			tx_count[63:5] <= tx_count[63:5] + 1'b1;
	assign msg_feed_complete = hash_process_flag && (st_q == StIdle);
	function automatic [0:0] sv2v_cast_1;
		input reg [0:0] inp;
		sv2v_cast_1 = inp;
	endfunction
endmodule
