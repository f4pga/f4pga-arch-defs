module hmac (
	clk_i,
	rst_ni,
	tl_i,
	tl_o,
	intr_hmac_done_o,
	intr_fifo_full_o,
	intr_hmac_err_o,
	alert_rx_i,
	alert_tx_o
);
	localparam [hmac_pkg_NumAlerts - 1:0] hmac_pkg_AlertAsyncOn = sv2v_cast_6747F(1'b1);
	localparam signed [31:0] hmac_pkg_NumAlerts = 1;
	localparam top_pkg_TL_AIW = 8;
	localparam top_pkg_TL_AW = 32;
	localparam top_pkg_TL_DBW = top_pkg_TL_DW >> 3;
	localparam top_pkg_TL_DIW = 1;
	localparam top_pkg_TL_DUW = 16;
	localparam top_pkg_TL_DW = 32;
	localparam top_pkg_TL_SZW = $clog2($clog2(32 >> 3) + 1);
	localparam ImplGeneric = 0;
	localparam ImplXilinx = 1;
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
			begin : sv2v_autoblock_4
				reg [31:0] _sv2v_strm_2F008_inp;
				reg [31:0] _sv2v_strm_2F008_out;
				integer _sv2v_strm_2F008_idx;
				integer _sv2v_strm_2F008_bas;
				_sv2v_strm_2F008_inp = v;
				for (_sv2v_strm_2F008_idx = 0; _sv2v_strm_2F008_idx <= 23; _sv2v_strm_2F008_idx = _sv2v_strm_2F008_idx + 8)
					_sv2v_strm_2F008_out[31 - _sv2v_strm_2F008_idx-:8] = _sv2v_strm_2F008_inp[_sv2v_strm_2F008_idx+:8];
				_sv2v_strm_2F008_bas = _sv2v_strm_2F008_idx;
				for (_sv2v_strm_2F008_idx = 0; _sv2v_strm_2F008_idx < (32 - _sv2v_strm_2F008_idx); _sv2v_strm_2F008_idx = _sv2v_strm_2F008_idx + 1)
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
	parameter signed [31:0] NumWords = 8;
	parameter [11:0] HMAC_INTR_STATE_OFFSET = 12'h 0;
	parameter [11:0] HMAC_INTR_ENABLE_OFFSET = 12'h 4;
	parameter [11:0] HMAC_INTR_TEST_OFFSET = 12'h 8;
	parameter [11:0] HMAC_CFG_OFFSET = 12'h c;
	parameter [11:0] HMAC_CMD_OFFSET = 12'h 10;
	parameter [11:0] HMAC_STATUS_OFFSET = 12'h 14;
	parameter [11:0] HMAC_ERR_CODE_OFFSET = 12'h 18;
	parameter [11:0] HMAC_WIPE_SECRET_OFFSET = 12'h 1c;
	parameter [11:0] HMAC_KEY0_OFFSET = 12'h 20;
	parameter [11:0] HMAC_KEY1_OFFSET = 12'h 24;
	parameter [11:0] HMAC_KEY2_OFFSET = 12'h 28;
	parameter [11:0] HMAC_KEY3_OFFSET = 12'h 2c;
	parameter [11:0] HMAC_KEY4_OFFSET = 12'h 30;
	parameter [11:0] HMAC_KEY5_OFFSET = 12'h 34;
	parameter [11:0] HMAC_KEY6_OFFSET = 12'h 38;
	parameter [11:0] HMAC_KEY7_OFFSET = 12'h 3c;
	parameter [11:0] HMAC_DIGEST0_OFFSET = 12'h 40;
	parameter [11:0] HMAC_DIGEST1_OFFSET = 12'h 44;
	parameter [11:0] HMAC_DIGEST2_OFFSET = 12'h 48;
	parameter [11:0] HMAC_DIGEST3_OFFSET = 12'h 4c;
	parameter [11:0] HMAC_DIGEST4_OFFSET = 12'h 50;
	parameter [11:0] HMAC_DIGEST5_OFFSET = 12'h 54;
	parameter [11:0] HMAC_DIGEST6_OFFSET = 12'h 58;
	parameter [11:0] HMAC_DIGEST7_OFFSET = 12'h 5c;
	parameter [11:0] HMAC_MSG_LENGTH_LOWER_OFFSET = 12'h 60;
	parameter [11:0] HMAC_MSG_LENGTH_UPPER_OFFSET = 12'h 64;
	parameter [11:0] HMAC_MSG_FIFO_OFFSET = 12'h 800;
	parameter [11:0] HMAC_MSG_FIFO_SIZE = 12'h 800;
	parameter [103:0] HMAC_PERMIT = {4'b 0001, 4'b 0001, 4'b 0001, 4'b 0001, 4'b 0001, 4'b 0011, 4'b 1111, 4'b 1111, 4'b 1111, 4'b 1111, 4'b 1111, 4'b 1111, 4'b 1111, 4'b 1111, 4'b 1111, 4'b 1111, 4'b 1111, 4'b 1111, 4'b 1111, 4'b 1111, 4'b 1111, 4'b 1111, 4'b 1111, 4'b 1111, 4'b 1111, 4'b 1111};
	localparam HMAC_INTR_STATE = 0;
	localparam HMAC_INTR_ENABLE = 1;
	localparam HMAC_KEY2 = 10;
	localparam HMAC_KEY3 = 11;
	localparam HMAC_KEY4 = 12;
	localparam HMAC_KEY5 = 13;
	localparam HMAC_KEY6 = 14;
	localparam HMAC_KEY7 = 15;
	localparam HMAC_DIGEST0 = 16;
	localparam HMAC_DIGEST1 = 17;
	localparam HMAC_DIGEST2 = 18;
	localparam HMAC_DIGEST3 = 19;
	localparam HMAC_INTR_TEST = 2;
	localparam HMAC_DIGEST4 = 20;
	localparam HMAC_DIGEST5 = 21;
	localparam HMAC_DIGEST6 = 22;
	localparam HMAC_DIGEST7 = 23;
	localparam HMAC_MSG_LENGTH_LOWER = 24;
	localparam HMAC_MSG_LENGTH_UPPER = 25;
	localparam HMAC_CFG = 3;
	localparam HMAC_CMD = 4;
	localparam HMAC_STATUS = 5;
	localparam HMAC_ERR_CODE = 6;
	localparam HMAC_WIPE_SECRET = 7;
	localparam HMAC_KEY0 = 8;
	localparam HMAC_KEY1 = 9;
	input clk_i;
	input rst_ni;
	input wire [((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_AW) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + top_pkg_TL_DW) + 17) - 1:0] tl_i;
	output wire [((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_DIW) + top_pkg_TL_DW) + top_pkg_TL_DUW) + 2) - 1:0] tl_o;
	output wire intr_hmac_done_o;
	output wire intr_fifo_full_o;
	output wire intr_hmac_err_o;
	input wire [(NumAlerts * 4) + -1:0] alert_rx_i;
	output wire [(NumAlerts * 2) + -1:0] alert_tx_o;
	wire [320:0] reg2hw;
	wire [627:0] hw2reg;
	wire [((((((7 + (($clog2($clog2(32 >> 3) + 1) - 1) >= 0 ? $clog2($clog2(32 >> 3) + 1) : 2 - $clog2($clog2(32 >> 3) + 1))) + 40) + (((32 >> 3) - 1) >= 0 ? 32 >> 3 : 2 - (32 >> 3))) + 49) - 1) >= 0 ? (((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_AW) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + top_pkg_TL_DW) + 16 : (2 - ((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_AW) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + top_pkg_TL_DW) + 17)) + ((((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_AW) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + top_pkg_TL_DW) + 17) - 1) - 1)):((((((7 + (($clog2($clog2(32 >> 3) + 1) - 1) >= 0 ? $clog2($clog2(32 >> 3) + 1) : 2 - $clog2($clog2(32 >> 3) + 1))) + 40) + (((32 >> 3) - 1) >= 0 ? 32 >> 3 : 2 - (32 >> 3))) + 49) - 1) >= 0 ? 0 : ((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_AW) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + top_pkg_TL_DW) + 17) - 1)] tl_win_h2d;
	wire [((((7 + (($clog2($clog2(32 >> 3) + 1) - 1) >= 0 ? $clog2($clog2(32 >> 3) + 1) : 2 - $clog2($clog2(32 >> 3) + 1))) + 59) - 1) >= 0 ? (((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_DIW) + top_pkg_TL_DW) + top_pkg_TL_DUW) + 1 : (2 - ((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_DIW) + top_pkg_TL_DW) + top_pkg_TL_DUW) + 2)) + ((((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_DIW) + top_pkg_TL_DW) + top_pkg_TL_DUW) + 2) - 1) - 1)):((((7 + (($clog2($clog2(32 >> 3) + 1) - 1) >= 0 ? $clog2($clog2(32 >> 3) + 1) : 2 - $clog2($clog2(32 >> 3) + 1))) + 59) - 1) >= 0 ? 0 : ((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_DIW) + top_pkg_TL_DW) + top_pkg_TL_DUW) + 2) - 1)] tl_win_d2h;
	reg [255:0] secret_key;
	wire wipe_secret;
	wire [31:0] wipe_v;
	wire fifo_rvalid;
	wire fifo_rready;
	wire [(32 + WordByte) - 1:0] fifo_rdata;
	wire fifo_wvalid;
	wire fifo_wready;
	wire [(32 + WordByte) - 1:0] fifo_wdata;
	wire fifo_full;
	wire fifo_empty;
	wire [4:0] fifo_depth;
	wire msg_fifo_req;
	wire msg_fifo_gnt;
	wire msg_fifo_we;
	wire [8:0] msg_fifo_addr;
	wire [31:0] msg_fifo_wdata;
	wire [31:0] msg_fifo_wmask;
	wire [31:0] msg_fifo_rdata;
	wire msg_fifo_rvalid;
	wire [1:0] msg_fifo_rerror;
	wire [31:0] msg_fifo_wdata_endian;
	wire [31:0] msg_fifo_wmask_endian;
	wire packer_ready;
	wire packer_flush_done;
	wire reg_fifo_wvalid;
	wire [31:0] reg_fifo_wdata;
	wire [31:0] reg_fifo_wmask;
	wire hmac_fifo_wsel;
	wire hmac_fifo_wvalid;
	wire [2:0] hmac_fifo_wdata_sel;
	wire shaf_rvalid;
	wire [(32 + WordByte) - 1:0] shaf_rdata;
	wire shaf_rready;
	wire sha_en;
	wire hmac_en;
	wire endian_swap;
	wire digest_swap;
	wire reg_hash_start;
	wire sha_hash_start;
	wire hash_start;
	wire reg_hash_process;
	wire sha_hash_process;
	wire reg_hash_done;
	wire sha_hash_done;
	reg [63:0] message_length;
	wire [63:0] sha_message_length;
	reg [31:0] err_code;
	wire err_valid;
	wire [255:0] digest;
	reg [7:0] cfg_reg;
	reg cfg_block;
	assign hw2reg[616] = fifo_full;
	assign hw2reg[617] = fifo_empty;
	assign hw2reg[615-:5] = fifo_depth;
	assign wipe_secret = reg2hw[264];
	assign wipe_v = reg2hw[296-:32];
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			secret_key <= 1'sb0;
		else if (wipe_secret)
			secret_key <= secret_key ^ {8 {wipe_v}};
		else if (!cfg_block) begin : sv2v_autoblock_136
			reg signed [31:0] i;
			for (i = 0; i < 8; i = i + 1)
				if (reg2hw[(7 - i) * 33])
					secret_key[32 * i+:32] <= reg2hw[((7 - i) * 33) + 32-:32];
		end
	generate
		genvar i;
		for (i = 0; i < 8; i = i + 1) begin : gen_key_digest
			assign hw2reg[322 + (((7 - i) * 32) + 31)-:32] = 1'sb0;
			assign hw2reg[66 + ((i * 32) + 31)-:32] = conv_endian(digest[i * 32+:32], digest_swap);
		end
	endgenerate
	wire [3:0] unused_cfg_qe;
	assign unused_cfg_qe = {cfg_reg[4], cfg_reg[6], cfg_reg[2], cfg_reg[0]};
	assign sha_en = cfg_reg[5];
	assign hmac_en = cfg_reg[7];
	assign endian_swap = cfg_reg[3];
	assign digest_swap = cfg_reg[1];
	assign hw2reg[621] = cfg_reg[7];
	assign hw2reg[620] = cfg_reg[5];
	assign hw2reg[619] = cfg_reg[3];
	assign hw2reg[618] = cfg_reg[1];
	assign reg_hash_start = reg2hw[299] & reg2hw[300];
	assign reg_hash_process = reg2hw[297] & reg2hw[298];
	assign hw2reg[578] = err_valid;
	assign hw2reg[610-:32] = err_code;
	assign hash_start = (reg_hash_start & sha_en) & ~cfg_block;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			cfg_block <= 1'sb0;
		else if (hash_start)
			cfg_block <= 1'b 1;
		else if (reg_hash_done)
			cfg_block <= 1'b 0;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			cfg_reg <= sv2v_struct_6856F(sv2v_struct_F6B41(1'sb0, 1'sb0), sv2v_struct_F6B41(1'sb0, 1'sb0), sv2v_struct_F6B41(1'b1, 1'b0), sv2v_struct_F6B41(1'sb0, 1'sb0));
		else if (!cfg_block && reg2hw[307])
			cfg_reg <= reg2hw[308-:8];
	reg fifo_full_q;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			fifo_full_q <= 1'b0;
		else
			fifo_full_q <= fifo_full;
	wire fifo_full_event;
	assign fifo_full_event = fifo_full & !fifo_full_q;
	wire [2:0] event_intr;
	assign event_intr = {err_valid, fifo_full_event, reg_hash_done};
	prim_intr_hw #(.Width(1)) intr_hw_hmac_done(
		.event_intr_i(event_intr[0]),
		.reg2hw_intr_enable_q_i(reg2hw[317]),
		.reg2hw_intr_test_q_i(reg2hw[314]),
		.reg2hw_intr_test_qe_i(reg2hw[313]),
		.reg2hw_intr_state_q_i(reg2hw[320]),
		.hw2reg_intr_state_de_o(hw2reg[626]),
		.hw2reg_intr_state_d_o(hw2reg[627]),
		.intr_o(intr_hmac_done_o)
	);
	prim_intr_hw #(.Width(1)) intr_hw_fifo_full(
		.event_intr_i(event_intr[1]),
		.reg2hw_intr_enable_q_i(reg2hw[316]),
		.reg2hw_intr_test_q_i(reg2hw[312]),
		.reg2hw_intr_test_qe_i(reg2hw[311]),
		.reg2hw_intr_state_q_i(reg2hw[319]),
		.hw2reg_intr_state_de_o(hw2reg[624]),
		.hw2reg_intr_state_d_o(hw2reg[625]),
		.intr_o(intr_fifo_full_o)
	);
	prim_intr_hw #(.Width(1)) intr_hw_hmac_err(
		.event_intr_i(event_intr[2]),
		.reg2hw_intr_enable_q_i(reg2hw[315]),
		.reg2hw_intr_test_q_i(reg2hw[310]),
		.reg2hw_intr_test_qe_i(reg2hw[309]),
		.reg2hw_intr_state_q_i(reg2hw[318]),
		.hw2reg_intr_state_de_o(hw2reg[622]),
		.hw2reg_intr_state_d_o(hw2reg[623]),
		.intr_o(intr_hmac_err_o)
	);
	assign msg_fifo_rvalid = msg_fifo_req & ~msg_fifo_we;
	assign msg_fifo_rdata = 1'sb1;
	assign msg_fifo_rerror = 1'sb1;
	assign msg_fifo_gnt = (msg_fifo_req & ~hmac_fifo_wsel) & packer_ready;
	wire [(32 + WordByte) - 1:0] reg_fifo_wentry;
	assign reg_fifo_wentry[32 + (WordByte + -1)-:((32 + (WordByte + -1)) - WordByte) + 1] = conv_endian(reg_fifo_wdata, 1'b1);
	assign reg_fifo_wentry[WordByte + -1-:WordByte] = {reg_fifo_wmask[0], reg_fifo_wmask[8], reg_fifo_wmask[16], reg_fifo_wmask[24]};
	assign fifo_full = ~fifo_wready;
	assign fifo_empty = ~fifo_rvalid;
	assign fifo_wvalid = (hmac_fifo_wsel && fifo_wready ? hmac_fifo_wvalid : reg_fifo_wvalid);
	assign fifo_wdata = (hmac_fifo_wsel ? sv2v_struct_C4A23(digest[hmac_fifo_wdata_sel * 32+:32], 1'sb1) : reg_fifo_wentry);
	prim_fifo_sync #(
		.Width(32 + WordByte),
		.Pass(1'b0),
		.Depth(MsgFifoDepth)
	) u_msg_fifo(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.clr_i(1'b0),
		.wvalid(fifo_wvalid & sha_en),
		.wready(fifo_wready),
		.wdata(fifo_wdata),
		.depth(fifo_depth),
		.rvalid(fifo_rvalid),
		.rready(fifo_rready),
		.rdata(fifo_rdata)
	);
	tlul_adapter_sram #(
		.SramAw(9),
		.SramDw(32),
		.Outstanding(1),
		.ByteAccess(1),
		.ErrOnRead(1)
	) u_tlul_adapter(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.tl_i(tl_win_h2d[((((((7 + (($clog2($clog2(32 >> 3) + 1) - 1) >= 0 ? $clog2($clog2(32 >> 3) + 1) : 2 - $clog2($clog2(32 >> 3) + 1))) + 40) + (((32 >> 3) - 1) >= 0 ? 32 >> 3 : 2 - (32 >> 3))) + 49) - 1) >= 0 ? 0 : ((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_AW) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + top_pkg_TL_DW) + 17) - 1)+:((((((7 + (($clog2($clog2(32 >> 3) + 1) - 1) >= 0 ? $clog2($clog2(32 >> 3) + 1) : 2 - $clog2($clog2(32 >> 3) + 1))) + 40) + (((32 >> 3) - 1) >= 0 ? 32 >> 3 : 2 - (32 >> 3))) + 49) - 1) >= 0 ? (((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_AW) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + top_pkg_TL_DW) + 17 : 2 - ((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_AW) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + top_pkg_TL_DW) + 17))]),
		.tl_o(tl_win_d2h[((((7 + (($clog2($clog2(32 >> 3) + 1) - 1) >= 0 ? $clog2($clog2(32 >> 3) + 1) : 2 - $clog2($clog2(32 >> 3) + 1))) + 59) - 1) >= 0 ? 0 : ((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_DIW) + top_pkg_TL_DW) + top_pkg_TL_DUW) + 2) - 1)+:((((7 + (($clog2($clog2(32 >> 3) + 1) - 1) >= 0 ? $clog2($clog2(32 >> 3) + 1) : 2 - $clog2($clog2(32 >> 3) + 1))) + 59) - 1) >= 0 ? (((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_DIW) + top_pkg_TL_DW) + top_pkg_TL_DUW) + 2 : 2 - ((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_DIW) + top_pkg_TL_DW) + top_pkg_TL_DUW) + 2))]),
		.req_o(msg_fifo_req),
		.gnt_i(msg_fifo_gnt),
		.we_o(msg_fifo_we),
		.addr_o(msg_fifo_addr),
		.wdata_o(msg_fifo_wdata),
		.wmask_o(msg_fifo_wmask),
		.rdata_i(msg_fifo_rdata),
		.rvalid_i(msg_fifo_rvalid),
		.rerror_i(msg_fifo_rerror)
	);
	wire msg_write;
	assign msg_write = (msg_fifo_req & msg_fifo_we) & ~hmac_fifo_wsel;
	reg [5:0] wmask_ones;
	always @(*) begin
		wmask_ones = 1'sb0;
		begin : sv2v_autoblock_137
			reg signed [31:0] i;
			for (i = 0; i < 32; i = i + 1)
				wmask_ones = wmask_ones + msg_fifo_wmask[i];
		end
	end
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			message_length <= 1'sb0;
		else if (hash_start)
			message_length <= 1'sb0;
		else if ((msg_write && sha_en) && packer_ready)
			message_length <= message_length + sv2v_cast_64(wmask_ones);
	assign hw2reg[0] = 1'b1;
	assign hw2reg[32-:32] = message_length[63:32];
	assign hw2reg[33] = 1'b1;
	assign hw2reg[65-:32] = message_length[31:0];
	assign msg_fifo_wdata_endian = conv_endian(msg_fifo_wdata, ~endian_swap);
	assign msg_fifo_wmask_endian = conv_endian(msg_fifo_wmask, ~endian_swap);
	prim_packer #(
		.InW(32),
		.OutW(32)
	) u_packer(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.valid_i(msg_write & sha_en),
		.data_i(msg_fifo_wdata_endian),
		.mask_i(msg_fifo_wmask_endian),
		.ready_o(packer_ready),
		.valid_o(reg_fifo_wvalid),
		.data_o(reg_fifo_wdata),
		.mask_o(reg_fifo_wmask),
		.ready_i(fifo_wready & ~hmac_fifo_wsel),
		.flush_i(reg_hash_process),
		.flush_done_o(packer_flush_done)
	);
	hmac_core u_hmac(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.secret_key(secret_key),
		.wipe_secret(wipe_secret),
		.wipe_v(wipe_v),
		.hmac_en(hmac_en),
		.reg_hash_start(hash_start),
		.reg_hash_process(packer_flush_done),
		.hash_done(reg_hash_done),
		.sha_hash_start(sha_hash_start),
		.sha_hash_process(sha_hash_process),
		.sha_hash_done(sha_hash_done),
		.sha_rvalid(shaf_rvalid),
		.sha_rdata(shaf_rdata),
		.sha_rready(shaf_rready),
		.fifo_rvalid(fifo_rvalid),
		.fifo_rdata(fifo_rdata),
		.fifo_rready(fifo_rready),
		.fifo_wsel(hmac_fifo_wsel),
		.fifo_wvalid(hmac_fifo_wvalid),
		.fifo_wdata_sel(hmac_fifo_wdata_sel),
		.fifo_wready(fifo_wready),
		.message_length(message_length),
		.sha_message_length(sha_message_length)
	);
	sha2 u_sha2(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.wipe_secret(wipe_secret),
		.wipe_v(wipe_v),
		.fifo_rvalid(shaf_rvalid),
		.fifo_rdata(shaf_rdata),
		.fifo_rready(shaf_rready),
		.sha_en(sha_en),
		.hash_start(sha_hash_start),
		.hash_process(sha_hash_process),
		.hash_done(sha_hash_done),
		.message_length(sha_message_length),
		.digest(digest)
	);
	hmac_reg_top u_reg(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.tl_i(tl_i),
		.tl_o(tl_o),
		.tl_win_o(tl_win_h2d),
		.tl_win_i(tl_win_d2h),
		.reg2hw(reg2hw),
		.hw2reg(hw2reg),
		.devmode_i(1'b1)
	);
	wire msg_push_sha_disabled;
	wire hash_start_sha_disabled;
	reg update_seckey_inprocess;
	wire hash_start_active;
	assign msg_push_sha_disabled = msg_write & ~sha_en;
	assign hash_start_sha_disabled = reg_hash_start & ~sha_en;
	assign hash_start_active = reg_hash_start & cfg_block;
	always @(*) begin
		update_seckey_inprocess = 1'b0;
		if (cfg_block) begin : sv2v_autoblock_138
			reg signed [31:0] i;
			for (i = 0; i < 8; i = i + 1)
				if (reg2hw[i * 33])
					update_seckey_inprocess = update_seckey_inprocess | 1'b1;
		end
		else
			update_seckey_inprocess = 1'b0;
	end
	assign err_valid = ~reg2hw[318] & (((msg_push_sha_disabled | hash_start_sha_disabled) | update_seckey_inprocess) | hash_start_active);
	always @(*) begin
		err_code = NoError;
		case (1'b1)
			msg_push_sha_disabled: err_code = SwPushMsgWhenShaDisabled;
			hash_start_sha_disabled: err_code = SwHashStartWhenShaDisabled;
			update_seckey_inprocess: err_code = SwUpdateSecretKeyInProcess;
			hash_start_active: err_code = SwHashStartWhenActive;
			default: err_code = NoError;
		endcase
	end
	wire [NumAlerts - 1:0] alerts;
	assign alerts = msg_push_sha_disabled;
	generate
		genvar j;
		for (j = 0; j < hmac_pkg_NumAlerts; j = j + 1) begin : gen_alert_tx
			prim_alert_sender #(.AsyncOn(hmac_pkg_AlertAsyncOn[j])) i_prim_alert_sender(
				.clk_i(clk_i),
				.rst_ni(rst_ni),
				.alert_i(alerts[j]),
				.alert_rx_i(alert_rx_i[j * 4+:4]),
				.alert_tx_o(alert_tx_o[j * 2+:2])
			);
		end
	endgenerate
	function automatic [1:0] sv2v_struct_F6B41;
		input reg q;
		input reg qe;
		sv2v_struct_F6B41 = {q, qe};
	endfunction
	function automatic [(32 + ((WordByte - 1) >= 0 ? WordByte : 2 - WordByte)) - 1:0] sv2v_struct_C4A23;
		input reg [31:0] data;
		input reg [WordByte - 1:0] mask;
		sv2v_struct_C4A23 = {data, mask};
	endfunction
	function automatic [0:0] sv2v_cast_1;
		input reg [0:0] inp;
		sv2v_cast_1 = inp;
	endfunction
	function automatic [63:0] sv2v_cast_64;
		input reg [63:0] inp;
		sv2v_cast_64 = inp;
	endfunction
	function automatic [hmac_pkg_NumAlerts - 1:0] sv2v_cast_6747F;
		input reg [hmac_pkg_NumAlerts - 1:0] inp;
		sv2v_cast_6747F = inp;
	endfunction
	function automatic [7:0] sv2v_struct_6856F;
		input reg [1:0] hmac_en;
		input reg [1:0] sha_en;
		input reg [1:0] endian_swap;
		input reg [1:0] digest_swap;
		sv2v_struct_6856F = {hmac_en, sha_en, endian_swap, digest_swap};
	endfunction
endmodule
