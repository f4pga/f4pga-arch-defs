module hmac_core (
	clk_i,
	rst_ni,
	secret_key,
	wipe_secret,
	wipe_v,
	hmac_en,
	reg_hash_start,
	reg_hash_process,
	hash_done,
	sha_hash_start,
	sha_hash_process,
	sha_hash_done,
	sha_rvalid,
	sha_rdata,
	sha_rready,
	fifo_rvalid,
	fifo_rdata,
	fifo_rready,
	fifo_wsel,
	fifo_wvalid,
	fifo_wdata_sel,
	fifo_wready,
	message_length,
	sha_message_length
);
	localparam [0:0] Inner = 0;
	localparam [0:0] SelIPadMsg = 0;
	localparam [1:0] SelIPad = 0;
	localparam [2:0] StIdle = 0;
	localparam [0:0] Outer = 1;
	localparam [0:0] SelOPadMsg = 1;
	localparam [1:0] SelOPad = 1;
	localparam [2:0] StIPad = 1;
	localparam [1:0] SelFifo = 2;
	localparam [2:0] StMsg = 2;
	localparam [2:0] StPushToMsgFifo = 3;
	localparam [2:0] StWaitResp = 4;
	localparam [2:0] StOPad = 5;
	localparam [2:0] StDone = 6;
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
			begin : sv2v_autoblock_3
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
	input [255:0] secret_key;
	input wipe_secret;
	input [31:0] wipe_v;
	input hmac_en;
	input reg_hash_start;
	input reg_hash_process;
	output wire hash_done;
	output wire sha_hash_start;
	output wire sha_hash_process;
	input sha_hash_done;
	output wire sha_rvalid;
	output wire [(32 + WordByte) - 1:0] sha_rdata;
	input sha_rready;
	input fifo_rvalid;
	input wire [(32 + WordByte) - 1:0] fifo_rdata;
	output wire fifo_rready;
	output reg fifo_wsel;
	output reg fifo_wvalid;
	output reg [2:0] fifo_wdata_sel;
	input fifo_wready;
	input [63:0] message_length;
	output [63:0] sha_message_length;
	localparam [31:0] BlockSize = 512;
	localparam [31:0] BlockSizeBits = 9;
	localparam [31:0] HashWordBits = 5;
	reg hash_start;
	reg hash_process;
	reg hmac_hash_done;
	wire [BlockSize - 1:0] i_pad;
	wire [BlockSize - 1:0] o_pad;
	reg [63:0] txcount;
	wire [(BlockSizeBits - HashWordBits) - 1:0] pad_index;
	reg clr_txcount;
	wire inc_txcount;
	reg hmac_sha_rvalid;
	reg [1:0] sel_rdata;
	wire [0:0] sel_msglen;
	reg update_round;
	reg [0:0] round_q;
	reg [0:0] round_d;
	reg [2:0] st_q;
	reg [2:0] st_d;
	reg clr_fifo_wdata_sel;
	wire txcnt_eq_blksz;
	reg reg_hash_process_flag;
	assign sha_hash_start = (hmac_en ? hash_start : reg_hash_start);
	assign sha_hash_process = (hmac_en ? reg_hash_process | hash_process : reg_hash_process);
	assign hash_done = (hmac_en ? hmac_hash_done : sha_hash_done);
	assign pad_index = txcount[BlockSizeBits - 1:HashWordBits];
	assign i_pad = {secret_key, {BlockSize - 256 {1'b0}}} ^ {BlockSize / 8 {8'h36}};
	assign o_pad = {secret_key, {BlockSize - 256 {1'b0}}} ^ {BlockSize / 8 {8'h5c}};
	assign fifo_rready = (hmac_en ? (st_q == StMsg) & sha_rready : sha_rready);
	assign sha_rvalid = (!hmac_en ? fifo_rvalid : hmac_sha_rvalid);
	assign sha_rdata = (!hmac_en ? fifo_rdata : (sel_rdata == SelIPad ? sv2v_struct_C4A23(i_pad[(BlockSize - 1) - (32 * pad_index)-:32], 1'sb1) : (sel_rdata == SelOPad ? sv2v_struct_C4A23(o_pad[(BlockSize - 1) - (32 * pad_index)-:32], 1'sb1) : (sel_rdata == SelFifo ? fifo_rdata : sv2v_struct_C4A23(1'sb0, 1'sb0)))));
	assign sha_message_length = (!hmac_en ? message_length : (sel_msglen == SelIPadMsg ? message_length + BlockSize : (sel_msglen == SelOPadMsg ? BlockSize + 256 : 1'sb0)));
	assign txcnt_eq_blksz = txcount[BlockSizeBits:0] == BlockSize;
	assign inc_txcount = sha_rready && sha_rvalid;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			txcount <= 1'sb0;
		else if (clr_txcount)
			txcount <= 1'sb0;
		else if (inc_txcount)
			txcount[63:5] <= txcount[63:5] + 1'b1;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			reg_hash_process_flag <= 1'b0;
		else if (reg_hash_process)
			reg_hash_process_flag <= 1'b1;
		else if (hmac_hash_done || reg_hash_start)
			reg_hash_process_flag <= 1'b0;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			round_q <= Inner;
		else if (update_round)
			round_q <= round_d;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			fifo_wdata_sel <= 3'h 0;
		else if (clr_fifo_wdata_sel)
			fifo_wdata_sel <= 3'h 0;
		else if (fifo_wsel && fifo_wvalid)
			fifo_wdata_sel <= fifo_wdata_sel + 1'b1;
	assign sel_msglen = (round_q == Inner ? SelIPadMsg : SelOPadMsg);
	always @(posedge clk_i or negedge rst_ni) begin : state_ff
		if (!rst_ni)
			st_q <= StIdle;
		else
			st_q <= st_d;
	end
	always @(*) begin : next_state
		hmac_hash_done = 1'b0;
		hmac_sha_rvalid = 1'b0;
		clr_txcount = 1'b0;
		update_round = 1'b0;
		round_d = Inner;
		fifo_wsel = 1'b0;
		fifo_wvalid = 1'b0;
		clr_fifo_wdata_sel = 1'b1;
		sel_rdata = SelFifo;
		hash_start = 1'b0;
		hash_process = 1'b0;
		case (st_q)
			StIdle:
				if (hmac_en && reg_hash_start) begin
					st_d = StIPad;
					clr_txcount = 1'b1;
					update_round = 1'b1;
					round_d = Inner;
					hash_start = 1'b1;
				end
				else
					st_d = StIdle;
			StIPad: begin
				sel_rdata = SelIPad;
				if (txcnt_eq_blksz) begin
					st_d = StMsg;
					hmac_sha_rvalid = 1'b0;
				end
				else begin
					st_d = StIPad;
					hmac_sha_rvalid = 1'b1;
				end
			end
			StMsg: begin
				sel_rdata = SelFifo;
				if ((((round_q == Inner) && reg_hash_process_flag) || (round_q == Outer)) && (txcount >= sha_message_length)) begin
					st_d = StWaitResp;
					hmac_sha_rvalid = 1'b0;
					hash_process = round_q == Outer;
				end
				else begin
					st_d = StMsg;
					hmac_sha_rvalid = fifo_rvalid;
				end
			end
			StWaitResp: begin
				hmac_sha_rvalid = 1'b0;
				if (sha_hash_done) begin
					if (round_q == Outer)
						st_d = StDone;
					else
						st_d = StPushToMsgFifo;
				end
				else
					st_d = StWaitResp;
			end
			StPushToMsgFifo: begin
				hmac_sha_rvalid = 1'b0;
				fifo_wsel = 1'b1;
				fifo_wvalid = 1'b1;
				clr_fifo_wdata_sel = 1'b0;
				if (fifo_wready && (fifo_wdata_sel == 3'h7)) begin
					st_d = StOPad;
					clr_txcount = 1'b1;
					update_round = 1'b1;
					round_d = Outer;
					hash_start = 1'b1;
				end
				else
					st_d = StPushToMsgFifo;
			end
			StOPad: begin
				sel_rdata = SelOPad;
				if (txcnt_eq_blksz) begin
					st_d = StMsg;
					hmac_sha_rvalid = 1'b0;
				end
				else begin
					st_d = StOPad;
					hmac_sha_rvalid = 1'b1;
				end
			end
			StDone: begin
				st_d = StIdle;
				hmac_hash_done = 1'b1;
			end
			default: st_d = StIdle;
		endcase
	end
	function automatic [(32 + ((WordByte - 1) >= 0 ? WordByte : 2 - WordByte)) - 1:0] sv2v_struct_C4A23;
		input reg [31:0] data;
		input reg [WordByte - 1:0] mask;
		sv2v_struct_C4A23 = {data, mask};
	endfunction
	function automatic [0:0] sv2v_cast_1;
		input reg [0:0] inp;
		sv2v_cast_1 = inp;
	endfunction
endmodule
