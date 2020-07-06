module hmac_reg_top (
	clk_i,
	rst_ni,
	tl_i,
	tl_o,
	tl_win_o,
	tl_win_i,
	reg2hw,
	hw2reg,
	devmode_i
);
	localparam top_pkg_TL_AIW = 8;
	localparam top_pkg_TL_AW = 32;
	localparam top_pkg_TL_DBW = top_pkg_TL_DW >> 3;
	localparam top_pkg_TL_DIW = 1;
	localparam top_pkg_TL_DUW = 16;
	localparam top_pkg_TL_DW = 32;
	localparam top_pkg_TL_SZW = $clog2($clog2(32 >> 3) + 1);
	input clk_i;
	input rst_ni;
	input wire [((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_AW) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + top_pkg_TL_DW) + 17) - 1:0] tl_i;
	output wire [((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_DIW) + top_pkg_TL_DW) + top_pkg_TL_DUW) + 2) - 1:0] tl_o;
	output wire [((((((7 + (($clog2($clog2(32 >> 3) + 1) - 1) >= 0 ? $clog2($clog2(32 >> 3) + 1) : 2 - $clog2($clog2(32 >> 3) + 1))) + 40) + (((32 >> 3) - 1) >= 0 ? 32 >> 3 : 2 - (32 >> 3))) + 49) - 1) >= 0 ? (((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_AW) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + top_pkg_TL_DW) + 16 : (2 - ((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_AW) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + top_pkg_TL_DW) + 17)) + ((((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_AW) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + top_pkg_TL_DW) + 17) - 1) - 1)):((((((7 + (($clog2($clog2(32 >> 3) + 1) - 1) >= 0 ? $clog2($clog2(32 >> 3) + 1) : 2 - $clog2($clog2(32 >> 3) + 1))) + 40) + (((32 >> 3) - 1) >= 0 ? 32 >> 3 : 2 - (32 >> 3))) + 49) - 1) >= 0 ? 0 : ((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_AW) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + top_pkg_TL_DW) + 17) - 1)] tl_win_o;
	input wire [((((7 + (($clog2($clog2(32 >> 3) + 1) - 1) >= 0 ? $clog2($clog2(32 >> 3) + 1) : 2 - $clog2($clog2(32 >> 3) + 1))) + 59) - 1) >= 0 ? (((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_DIW) + top_pkg_TL_DW) + top_pkg_TL_DUW) + 1 : (2 - ((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_DIW) + top_pkg_TL_DW) + top_pkg_TL_DUW) + 2)) + ((((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_DIW) + top_pkg_TL_DW) + top_pkg_TL_DUW) + 2) - 1) - 1)):((((7 + (($clog2($clog2(32 >> 3) + 1) - 1) >= 0 ? $clog2($clog2(32 >> 3) + 1) : 2 - $clog2($clog2(32 >> 3) + 1))) + 59) - 1) >= 0 ? 0 : ((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_DIW) + top_pkg_TL_DW) + top_pkg_TL_DUW) + 2) - 1)] tl_win_i;
	output wire [320:0] reg2hw;
	input wire [627:0] hw2reg;
	input devmode_i;
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
	localparam signed [31:0] AW = 12;
	localparam signed [31:0] DW = 32;
	localparam signed [31:0] DBW = DW / 8;
	wire reg_we;
	wire reg_re;
	wire [AW - 1:0] reg_addr;
	wire [DW - 1:0] reg_wdata;
	wire [DBW - 1:0] reg_be;
	wire [DW - 1:0] reg_rdata;
	wire reg_error;
	wire addrmiss;
	reg wr_err;
	reg [DW - 1:0] reg_rdata_next;
	wire [((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_AW) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + top_pkg_TL_DW) + 17) - 1:0] tl_reg_h2d;
	wire [((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_DIW) + top_pkg_TL_DW) + top_pkg_TL_DUW) + 2) - 1:0] tl_reg_d2h;
	wire [((((((7 + (($clog2($clog2(32 >> 3) + 1) - 1) >= 0 ? $clog2($clog2(32 >> 3) + 1) : 2 - $clog2($clog2(32 >> 3) + 1))) + 40) + (((32 >> 3) - 1) >= 0 ? 32 >> 3 : 2 - (32 >> 3))) + 49) - 1) >= 0 ? (2 * ((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_AW) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + top_pkg_TL_DW) + 17)) + -1 : (2 * (2 - ((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_AW) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + top_pkg_TL_DW) + 17))) + ((((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_AW) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + top_pkg_TL_DW) + 17) - 1) - 1)):((((((7 + (($clog2($clog2(32 >> 3) + 1) - 1) >= 0 ? $clog2($clog2(32 >> 3) + 1) : 2 - $clog2($clog2(32 >> 3) + 1))) + 40) + (((32 >> 3) - 1) >= 0 ? 32 >> 3 : 2 - (32 >> 3))) + 49) - 1) >= 0 ? 0 : ((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_AW) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + top_pkg_TL_DW) + 17) - 1)] tl_socket_h2d;
	wire [((((7 + (($clog2($clog2(32 >> 3) + 1) - 1) >= 0 ? $clog2($clog2(32 >> 3) + 1) : 2 - $clog2($clog2(32 >> 3) + 1))) + 59) - 1) >= 0 ? (2 * ((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_DIW) + top_pkg_TL_DW) + top_pkg_TL_DUW) + 2)) + -1 : (2 * (2 - ((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_DIW) + top_pkg_TL_DW) + top_pkg_TL_DUW) + 2))) + ((((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_DIW) + top_pkg_TL_DW) + top_pkg_TL_DUW) + 2) - 1) - 1)):((((7 + (($clog2($clog2(32 >> 3) + 1) - 1) >= 0 ? $clog2($clog2(32 >> 3) + 1) : 2 - $clog2($clog2(32 >> 3) + 1))) + 59) - 1) >= 0 ? 0 : ((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_DIW) + top_pkg_TL_DW) + top_pkg_TL_DUW) + 2) - 1)] tl_socket_d2h;
	reg [1:0] reg_steer;
	assign tl_reg_h2d = tl_socket_h2d[((((((7 + (($clog2($clog2(32 >> 3) + 1) - 1) >= 0 ? $clog2($clog2(32 >> 3) + 1) : 2 - $clog2($clog2(32 >> 3) + 1))) + 40) + (((32 >> 3) - 1) >= 0 ? 32 >> 3 : 2 - (32 >> 3))) + 49) - 1) >= 0 ? 0 : ((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_AW) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + top_pkg_TL_DW) + 17) - 1)+:((((((7 + (($clog2($clog2(32 >> 3) + 1) - 1) >= 0 ? $clog2($clog2(32 >> 3) + 1) : 2 - $clog2($clog2(32 >> 3) + 1))) + 40) + (((32 >> 3) - 1) >= 0 ? 32 >> 3 : 2 - (32 >> 3))) + 49) - 1) >= 0 ? (((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_AW) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + top_pkg_TL_DW) + 17 : 2 - ((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_AW) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + top_pkg_TL_DW) + 17))];
	assign tl_socket_d2h[((((7 + (($clog2($clog2(32 >> 3) + 1) - 1) >= 0 ? $clog2($clog2(32 >> 3) + 1) : 2 - $clog2($clog2(32 >> 3) + 1))) + 59) - 1) >= 0 ? 0 : ((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_DIW) + top_pkg_TL_DW) + top_pkg_TL_DUW) + 2) - 1)+:((((7 + (($clog2($clog2(32 >> 3) + 1) - 1) >= 0 ? $clog2($clog2(32 >> 3) + 1) : 2 - $clog2($clog2(32 >> 3) + 1))) + 59) - 1) >= 0 ? (((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_DIW) + top_pkg_TL_DW) + top_pkg_TL_DUW) + 2 : 2 - ((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_DIW) + top_pkg_TL_DW) + top_pkg_TL_DUW) + 2))] = tl_reg_d2h;
	assign tl_win_o[((((((7 + (($clog2($clog2(32 >> 3) + 1) - 1) >= 0 ? $clog2($clog2(32 >> 3) + 1) : 2 - $clog2($clog2(32 >> 3) + 1))) + 40) + (((32 >> 3) - 1) >= 0 ? 32 >> 3 : 2 - (32 >> 3))) + 49) - 1) >= 0 ? 0 : ((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_AW) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + top_pkg_TL_DW) + 17) - 1)+:((((((7 + (($clog2($clog2(32 >> 3) + 1) - 1) >= 0 ? $clog2($clog2(32 >> 3) + 1) : 2 - $clog2($clog2(32 >> 3) + 1))) + 40) + (((32 >> 3) - 1) >= 0 ? 32 >> 3 : 2 - (32 >> 3))) + 49) - 1) >= 0 ? (((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_AW) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + top_pkg_TL_DW) + 17 : 2 - ((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_AW) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + top_pkg_TL_DW) + 17))] = tl_socket_h2d[((((((7 + (($clog2($clog2(32 >> 3) + 1) - 1) >= 0 ? $clog2($clog2(32 >> 3) + 1) : 2 - $clog2($clog2(32 >> 3) + 1))) + 40) + (((32 >> 3) - 1) >= 0 ? 32 >> 3 : 2 - (32 >> 3))) + 49) - 1) >= 0 ? 0 : ((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_AW) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + top_pkg_TL_DW) + 17) - 1) + ((((((7 + (($clog2($clog2(32 >> 3) + 1) - 1) >= 0 ? $clog2($clog2(32 >> 3) + 1) : 2 - $clog2($clog2(32 >> 3) + 1))) + 40) + (((32 >> 3) - 1) >= 0 ? 32 >> 3 : 2 - (32 >> 3))) + 49) - 1) >= 0 ? (((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_AW) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + top_pkg_TL_DW) + 17 : 2 - ((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_AW) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + top_pkg_TL_DW) + 17))+:((((((7 + (($clog2($clog2(32 >> 3) + 1) - 1) >= 0 ? $clog2($clog2(32 >> 3) + 1) : 2 - $clog2($clog2(32 >> 3) + 1))) + 40) + (((32 >> 3) - 1) >= 0 ? 32 >> 3 : 2 - (32 >> 3))) + 49) - 1) >= 0 ? (((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_AW) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + top_pkg_TL_DW) + 17 : 2 - ((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_AW) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + top_pkg_TL_DW) + 17))];
	assign tl_socket_d2h[((((7 + (($clog2($clog2(32 >> 3) + 1) - 1) >= 0 ? $clog2($clog2(32 >> 3) + 1) : 2 - $clog2($clog2(32 >> 3) + 1))) + 59) - 1) >= 0 ? 0 : ((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_DIW) + top_pkg_TL_DW) + top_pkg_TL_DUW) + 2) - 1) + ((((7 + (($clog2($clog2(32 >> 3) + 1) - 1) >= 0 ? $clog2($clog2(32 >> 3) + 1) : 2 - $clog2($clog2(32 >> 3) + 1))) + 59) - 1) >= 0 ? (((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_DIW) + top_pkg_TL_DW) + top_pkg_TL_DUW) + 2 : 2 - ((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_DIW) + top_pkg_TL_DW) + top_pkg_TL_DUW) + 2))+:((((7 + (($clog2($clog2(32 >> 3) + 1) - 1) >= 0 ? $clog2($clog2(32 >> 3) + 1) : 2 - $clog2($clog2(32 >> 3) + 1))) + 59) - 1) >= 0 ? (((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_DIW) + top_pkg_TL_DW) + top_pkg_TL_DUW) + 2 : 2 - ((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_DIW) + top_pkg_TL_DW) + top_pkg_TL_DUW) + 2))] = tl_win_i[((((7 + (($clog2($clog2(32 >> 3) + 1) - 1) >= 0 ? $clog2($clog2(32 >> 3) + 1) : 2 - $clog2($clog2(32 >> 3) + 1))) + 59) - 1) >= 0 ? 0 : ((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_DIW) + top_pkg_TL_DW) + top_pkg_TL_DUW) + 2) - 1)+:((((7 + (($clog2($clog2(32 >> 3) + 1) - 1) >= 0 ? $clog2($clog2(32 >> 3) + 1) : 2 - $clog2($clog2(32 >> 3) + 1))) + 59) - 1) >= 0 ? (((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_DIW) + top_pkg_TL_DW) + top_pkg_TL_DUW) + 2 : 2 - ((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_DIW) + top_pkg_TL_DW) + top_pkg_TL_DUW) + 2))];
	tlul_socket_1n #(
		.N(2),
		.HReqPass(1'b1),
		.HRspPass(1'b1),
		.DReqPass({2 {1'b1}}),
		.DRspPass({2 {1'b1}}),
		.HReqDepth(4'h0),
		.HRspDepth(4'h0),
		.DReqDepth({2 {4'h0}}),
		.DRspDepth({2 {4'h0}})
	) u_socket(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.tl_h_i(tl_i),
		.tl_h_o(tl_o),
		.tl_d_o(tl_socket_h2d),
		.tl_d_i(tl_socket_d2h),
		.dev_select(reg_steer)
	);
	always @(*) begin
		reg_steer = 1;
		if (tl_i[(top_pkg_TL_AW + (((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW) + (top_pkg_TL_DW + 16))) - ((top_pkg_TL_AW - 1) - (AW - 1)):(top_pkg_TL_AW + (((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW) + (top_pkg_TL_DW + 16))) - (top_pkg_TL_AW - 1)] >= 2048)
			reg_steer = 0;
	end
	tlul_adapter_reg #(
		.RegAw(AW),
		.RegDw(DW)
	) u_reg_if(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.tl_i(tl_reg_h2d),
		.tl_o(tl_reg_d2h),
		.we_o(reg_we),
		.re_o(reg_re),
		.addr_o(reg_addr),
		.wdata_o(reg_wdata),
		.be_o(reg_be),
		.rdata_i(reg_rdata),
		.error_i(reg_error)
	);
	assign reg_rdata = reg_rdata_next;
	assign reg_error = (devmode_i & addrmiss) | wr_err;
	wire intr_state_hmac_done_qs;
	wire intr_state_hmac_done_wd;
	wire intr_state_hmac_done_we;
	wire intr_state_fifo_full_qs;
	wire intr_state_fifo_full_wd;
	wire intr_state_fifo_full_we;
	wire intr_state_hmac_err_qs;
	wire intr_state_hmac_err_wd;
	wire intr_state_hmac_err_we;
	wire intr_enable_hmac_done_qs;
	wire intr_enable_hmac_done_wd;
	wire intr_enable_hmac_done_we;
	wire intr_enable_fifo_full_qs;
	wire intr_enable_fifo_full_wd;
	wire intr_enable_fifo_full_we;
	wire intr_enable_hmac_err_qs;
	wire intr_enable_hmac_err_wd;
	wire intr_enable_hmac_err_we;
	wire intr_test_hmac_done_wd;
	wire intr_test_hmac_done_we;
	wire intr_test_fifo_full_wd;
	wire intr_test_fifo_full_we;
	wire intr_test_hmac_err_wd;
	wire intr_test_hmac_err_we;
	wire cfg_hmac_en_qs;
	wire cfg_hmac_en_wd;
	wire cfg_hmac_en_we;
	wire cfg_hmac_en_re;
	wire cfg_sha_en_qs;
	wire cfg_sha_en_wd;
	wire cfg_sha_en_we;
	wire cfg_sha_en_re;
	wire cfg_endian_swap_qs;
	wire cfg_endian_swap_wd;
	wire cfg_endian_swap_we;
	wire cfg_endian_swap_re;
	wire cfg_digest_swap_qs;
	wire cfg_digest_swap_wd;
	wire cfg_digest_swap_we;
	wire cfg_digest_swap_re;
	wire cmd_hash_start_wd;
	wire cmd_hash_start_we;
	wire cmd_hash_process_wd;
	wire cmd_hash_process_we;
	wire status_fifo_empty_qs;
	wire status_fifo_empty_re;
	wire status_fifo_full_qs;
	wire status_fifo_full_re;
	wire [4:0] status_fifo_depth_qs;
	wire status_fifo_depth_re;
	wire [31:0] err_code_qs;
	wire [31:0] wipe_secret_wd;
	wire wipe_secret_we;
	wire [31:0] key0_wd;
	wire key0_we;
	wire [31:0] key1_wd;
	wire key1_we;
	wire [31:0] key2_wd;
	wire key2_we;
	wire [31:0] key3_wd;
	wire key3_we;
	wire [31:0] key4_wd;
	wire key4_we;
	wire [31:0] key5_wd;
	wire key5_we;
	wire [31:0] key6_wd;
	wire key6_we;
	wire [31:0] key7_wd;
	wire key7_we;
	wire [31:0] digest0_qs;
	wire digest0_re;
	wire [31:0] digest1_qs;
	wire digest1_re;
	wire [31:0] digest2_qs;
	wire digest2_re;
	wire [31:0] digest3_qs;
	wire digest3_re;
	wire [31:0] digest4_qs;
	wire digest4_re;
	wire [31:0] digest5_qs;
	wire digest5_re;
	wire [31:0] digest6_qs;
	wire digest6_re;
	wire [31:0] digest7_qs;
	wire digest7_re;
	wire [31:0] msg_length_lower_qs;
	wire [31:0] msg_length_upper_qs;
	prim_subreg #(
		.DW(1),
		.SWACCESS("W1C"),
		.RESVAL(1'h0)
	) u_intr_state_hmac_done(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(intr_state_hmac_done_we),
		.wd(intr_state_hmac_done_wd),
		.de(hw2reg[626]),
		.d(hw2reg[627]),
		.qe(),
		.q(reg2hw[320]),
		.qs(intr_state_hmac_done_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("W1C"),
		.RESVAL(1'h0)
	) u_intr_state_fifo_full(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(intr_state_fifo_full_we),
		.wd(intr_state_fifo_full_wd),
		.de(hw2reg[624]),
		.d(hw2reg[625]),
		.qe(),
		.q(reg2hw[319]),
		.qs(intr_state_fifo_full_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("W1C"),
		.RESVAL(1'h0)
	) u_intr_state_hmac_err(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(intr_state_hmac_err_we),
		.wd(intr_state_hmac_err_wd),
		.de(hw2reg[622]),
		.d(hw2reg[623]),
		.qe(),
		.q(reg2hw[318]),
		.qs(intr_state_hmac_err_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_intr_enable_hmac_done(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(intr_enable_hmac_done_we),
		.wd(intr_enable_hmac_done_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[317]),
		.qs(intr_enable_hmac_done_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_intr_enable_fifo_full(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(intr_enable_fifo_full_we),
		.wd(intr_enable_fifo_full_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[316]),
		.qs(intr_enable_fifo_full_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_intr_enable_hmac_err(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(intr_enable_hmac_err_we),
		.wd(intr_enable_hmac_err_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[315]),
		.qs(intr_enable_hmac_err_qs)
	);
	prim_subreg_ext #(.DW(1)) u_intr_test_hmac_done(
		.re(1'b0),
		.we(intr_test_hmac_done_we),
		.wd(intr_test_hmac_done_wd),
		.d(1'sb0),
		.qre(),
		.qe(reg2hw[313]),
		.q(reg2hw[314]),
		.qs()
	);
	prim_subreg_ext #(.DW(1)) u_intr_test_fifo_full(
		.re(1'b0),
		.we(intr_test_fifo_full_we),
		.wd(intr_test_fifo_full_wd),
		.d(1'sb0),
		.qre(),
		.qe(reg2hw[311]),
		.q(reg2hw[312]),
		.qs()
	);
	prim_subreg_ext #(.DW(1)) u_intr_test_hmac_err(
		.re(1'b0),
		.we(intr_test_hmac_err_we),
		.wd(intr_test_hmac_err_wd),
		.d(1'sb0),
		.qre(),
		.qe(reg2hw[309]),
		.q(reg2hw[310]),
		.qs()
	);
	prim_subreg_ext #(.DW(1)) u_cfg_hmac_en(
		.re(cfg_hmac_en_re),
		.we(cfg_hmac_en_we),
		.wd(cfg_hmac_en_wd),
		.d(hw2reg[621]),
		.qre(),
		.qe(reg2hw[307]),
		.q(reg2hw[308]),
		.qs(cfg_hmac_en_qs)
	);
	prim_subreg_ext #(.DW(1)) u_cfg_sha_en(
		.re(cfg_sha_en_re),
		.we(cfg_sha_en_we),
		.wd(cfg_sha_en_wd),
		.d(hw2reg[620]),
		.qre(),
		.qe(reg2hw[305]),
		.q(reg2hw[306]),
		.qs(cfg_sha_en_qs)
	);
	prim_subreg_ext #(.DW(1)) u_cfg_endian_swap(
		.re(cfg_endian_swap_re),
		.we(cfg_endian_swap_we),
		.wd(cfg_endian_swap_wd),
		.d(hw2reg[619]),
		.qre(),
		.qe(reg2hw[303]),
		.q(reg2hw[304]),
		.qs(cfg_endian_swap_qs)
	);
	prim_subreg_ext #(.DW(1)) u_cfg_digest_swap(
		.re(cfg_digest_swap_re),
		.we(cfg_digest_swap_we),
		.wd(cfg_digest_swap_wd),
		.d(hw2reg[618]),
		.qre(),
		.qe(reg2hw[301]),
		.q(reg2hw[302]),
		.qs(cfg_digest_swap_qs)
	);
	prim_subreg_ext #(.DW(1)) u_cmd_hash_start(
		.re(1'b0),
		.we(cmd_hash_start_we),
		.wd(cmd_hash_start_wd),
		.d(1'sb0),
		.qre(),
		.qe(reg2hw[299]),
		.q(reg2hw[300]),
		.qs()
	);
	prim_subreg_ext #(.DW(1)) u_cmd_hash_process(
		.re(1'b0),
		.we(cmd_hash_process_we),
		.wd(cmd_hash_process_wd),
		.d(1'sb0),
		.qre(),
		.qe(reg2hw[297]),
		.q(reg2hw[298]),
		.qs()
	);
	prim_subreg_ext #(.DW(1)) u_status_fifo_empty(
		.re(status_fifo_empty_re),
		.we(1'b0),
		.wd(1'sb0),
		.d(hw2reg[617]),
		.qre(),
		.qe(),
		.q(),
		.qs(status_fifo_empty_qs)
	);
	prim_subreg_ext #(.DW(1)) u_status_fifo_full(
		.re(status_fifo_full_re),
		.we(1'b0),
		.wd(1'sb0),
		.d(hw2reg[616]),
		.qre(),
		.qe(),
		.q(),
		.qs(status_fifo_full_qs)
	);
	prim_subreg_ext #(.DW(5)) u_status_fifo_depth(
		.re(status_fifo_depth_re),
		.we(1'b0),
		.wd(1'sb0),
		.d(hw2reg[615-:5]),
		.qre(),
		.qe(),
		.q(),
		.qs(status_fifo_depth_qs)
	);
	prim_subreg #(
		.DW(32),
		.SWACCESS("RO"),
		.RESVAL(32'h0)
	) u_err_code(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(1'b0),
		.wd(1'sb0),
		.de(hw2reg[578]),
		.d(hw2reg[610-:32]),
		.qe(),
		.q(),
		.qs(err_code_qs)
	);
	prim_subreg_ext #(.DW(32)) u_wipe_secret(
		.re(1'b0),
		.we(wipe_secret_we),
		.wd(wipe_secret_wd),
		.d(1'sb0),
		.qre(),
		.qe(reg2hw[264]),
		.q(reg2hw[296-:32]),
		.qs()
	);
	prim_subreg_ext #(.DW(32)) u_key0(
		.re(1'b0),
		.we(key0_we),
		.wd(key0_wd),
		.d(hw2reg[353-:32]),
		.qre(),
		.qe(reg2hw[0]),
		.q(reg2hw[32-:32]),
		.qs()
	);
	prim_subreg_ext #(.DW(32)) u_key1(
		.re(1'b0),
		.we(key1_we),
		.wd(key1_wd),
		.d(hw2reg[385-:32]),
		.qre(),
		.qe(reg2hw[33]),
		.q(reg2hw[65-:32]),
		.qs()
	);
	prim_subreg_ext #(.DW(32)) u_key2(
		.re(1'b0),
		.we(key2_we),
		.wd(key2_wd),
		.d(hw2reg[417-:32]),
		.qre(),
		.qe(reg2hw[66]),
		.q(reg2hw[98-:32]),
		.qs()
	);
	prim_subreg_ext #(.DW(32)) u_key3(
		.re(1'b0),
		.we(key3_we),
		.wd(key3_wd),
		.d(hw2reg[449-:32]),
		.qre(),
		.qe(reg2hw[99]),
		.q(reg2hw[131-:32]),
		.qs()
	);
	prim_subreg_ext #(.DW(32)) u_key4(
		.re(1'b0),
		.we(key4_we),
		.wd(key4_wd),
		.d(hw2reg[481-:32]),
		.qre(),
		.qe(reg2hw[132]),
		.q(reg2hw[164-:32]),
		.qs()
	);
	prim_subreg_ext #(.DW(32)) u_key5(
		.re(1'b0),
		.we(key5_we),
		.wd(key5_wd),
		.d(hw2reg[513-:32]),
		.qre(),
		.qe(reg2hw[165]),
		.q(reg2hw[197-:32]),
		.qs()
	);
	prim_subreg_ext #(.DW(32)) u_key6(
		.re(1'b0),
		.we(key6_we),
		.wd(key6_wd),
		.d(hw2reg[545-:32]),
		.qre(),
		.qe(reg2hw[198]),
		.q(reg2hw[230-:32]),
		.qs()
	);
	prim_subreg_ext #(.DW(32)) u_key7(
		.re(1'b0),
		.we(key7_we),
		.wd(key7_wd),
		.d(hw2reg[577-:32]),
		.qre(),
		.qe(reg2hw[231]),
		.q(reg2hw[263-:32]),
		.qs()
	);
	prim_subreg_ext #(.DW(32)) u_digest0(
		.re(digest0_re),
		.we(1'b0),
		.wd(1'sb0),
		.d(hw2reg[97-:32]),
		.qre(),
		.qe(),
		.q(),
		.qs(digest0_qs)
	);
	prim_subreg_ext #(.DW(32)) u_digest1(
		.re(digest1_re),
		.we(1'b0),
		.wd(1'sb0),
		.d(hw2reg[129-:32]),
		.qre(),
		.qe(),
		.q(),
		.qs(digest1_qs)
	);
	prim_subreg_ext #(.DW(32)) u_digest2(
		.re(digest2_re),
		.we(1'b0),
		.wd(1'sb0),
		.d(hw2reg[161-:32]),
		.qre(),
		.qe(),
		.q(),
		.qs(digest2_qs)
	);
	prim_subreg_ext #(.DW(32)) u_digest3(
		.re(digest3_re),
		.we(1'b0),
		.wd(1'sb0),
		.d(hw2reg[193-:32]),
		.qre(),
		.qe(),
		.q(),
		.qs(digest3_qs)
	);
	prim_subreg_ext #(.DW(32)) u_digest4(
		.re(digest4_re),
		.we(1'b0),
		.wd(1'sb0),
		.d(hw2reg[225-:32]),
		.qre(),
		.qe(),
		.q(),
		.qs(digest4_qs)
	);
	prim_subreg_ext #(.DW(32)) u_digest5(
		.re(digest5_re),
		.we(1'b0),
		.wd(1'sb0),
		.d(hw2reg[257-:32]),
		.qre(),
		.qe(),
		.q(),
		.qs(digest5_qs)
	);
	prim_subreg_ext #(.DW(32)) u_digest6(
		.re(digest6_re),
		.we(1'b0),
		.wd(1'sb0),
		.d(hw2reg[289-:32]),
		.qre(),
		.qe(),
		.q(),
		.qs(digest6_qs)
	);
	prim_subreg_ext #(.DW(32)) u_digest7(
		.re(digest7_re),
		.we(1'b0),
		.wd(1'sb0),
		.d(hw2reg[321-:32]),
		.qre(),
		.qe(),
		.q(),
		.qs(digest7_qs)
	);
	prim_subreg #(
		.DW(32),
		.SWACCESS("RO"),
		.RESVAL(32'h0)
	) u_msg_length_lower(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(1'b0),
		.wd(1'sb0),
		.de(hw2reg[33]),
		.d(hw2reg[65-:32]),
		.qe(),
		.q(),
		.qs(msg_length_lower_qs)
	);
	prim_subreg #(
		.DW(32),
		.SWACCESS("RO"),
		.RESVAL(32'h0)
	) u_msg_length_upper(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(1'b0),
		.wd(1'sb0),
		.de(hw2reg[0]),
		.d(hw2reg[32-:32]),
		.qe(),
		.q(),
		.qs(msg_length_upper_qs)
	);
	reg [25:0] addr_hit;
	always @(*) begin
		addr_hit = 1'sb0;
		addr_hit[0] = reg_addr == HMAC_INTR_STATE_OFFSET;
		addr_hit[1] = reg_addr == HMAC_INTR_ENABLE_OFFSET;
		addr_hit[2] = reg_addr == HMAC_INTR_TEST_OFFSET;
		addr_hit[3] = reg_addr == HMAC_CFG_OFFSET;
		addr_hit[4] = reg_addr == HMAC_CMD_OFFSET;
		addr_hit[5] = reg_addr == HMAC_STATUS_OFFSET;
		addr_hit[6] = reg_addr == HMAC_ERR_CODE_OFFSET;
		addr_hit[7] = reg_addr == HMAC_WIPE_SECRET_OFFSET;
		addr_hit[8] = reg_addr == HMAC_KEY0_OFFSET;
		addr_hit[9] = reg_addr == HMAC_KEY1_OFFSET;
		addr_hit[10] = reg_addr == HMAC_KEY2_OFFSET;
		addr_hit[11] = reg_addr == HMAC_KEY3_OFFSET;
		addr_hit[12] = reg_addr == HMAC_KEY4_OFFSET;
		addr_hit[13] = reg_addr == HMAC_KEY5_OFFSET;
		addr_hit[14] = reg_addr == HMAC_KEY6_OFFSET;
		addr_hit[15] = reg_addr == HMAC_KEY7_OFFSET;
		addr_hit[16] = reg_addr == HMAC_DIGEST0_OFFSET;
		addr_hit[17] = reg_addr == HMAC_DIGEST1_OFFSET;
		addr_hit[18] = reg_addr == HMAC_DIGEST2_OFFSET;
		addr_hit[19] = reg_addr == HMAC_DIGEST3_OFFSET;
		addr_hit[20] = reg_addr == HMAC_DIGEST4_OFFSET;
		addr_hit[21] = reg_addr == HMAC_DIGEST5_OFFSET;
		addr_hit[22] = reg_addr == HMAC_DIGEST6_OFFSET;
		addr_hit[23] = reg_addr == HMAC_DIGEST7_OFFSET;
		addr_hit[24] = reg_addr == HMAC_MSG_LENGTH_LOWER_OFFSET;
		addr_hit[25] = reg_addr == HMAC_MSG_LENGTH_UPPER_OFFSET;
	end
	assign addrmiss = (reg_re || reg_we ? ~|addr_hit : 1'b0);
	always @(*) begin
		wr_err = 1'b0;
		if ((addr_hit[0] && reg_we) && (HMAC_PERMIT[100+:4] != (HMAC_PERMIT[100+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[1] && reg_we) && (HMAC_PERMIT[96+:4] != (HMAC_PERMIT[96+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[2] && reg_we) && (HMAC_PERMIT[92+:4] != (HMAC_PERMIT[92+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[3] && reg_we) && (HMAC_PERMIT[88+:4] != (HMAC_PERMIT[88+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[4] && reg_we) && (HMAC_PERMIT[84+:4] != (HMAC_PERMIT[84+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[5] && reg_we) && (HMAC_PERMIT[80+:4] != (HMAC_PERMIT[80+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[6] && reg_we) && (HMAC_PERMIT[76+:4] != (HMAC_PERMIT[76+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[7] && reg_we) && (HMAC_PERMIT[72+:4] != (HMAC_PERMIT[72+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[8] && reg_we) && (HMAC_PERMIT[68+:4] != (HMAC_PERMIT[68+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[9] && reg_we) && (HMAC_PERMIT[64+:4] != (HMAC_PERMIT[64+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[10] && reg_we) && (HMAC_PERMIT[60+:4] != (HMAC_PERMIT[60+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[11] && reg_we) && (HMAC_PERMIT[56+:4] != (HMAC_PERMIT[56+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[12] && reg_we) && (HMAC_PERMIT[52+:4] != (HMAC_PERMIT[52+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[13] && reg_we) && (HMAC_PERMIT[48+:4] != (HMAC_PERMIT[48+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[14] && reg_we) && (HMAC_PERMIT[44+:4] != (HMAC_PERMIT[44+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[15] && reg_we) && (HMAC_PERMIT[40+:4] != (HMAC_PERMIT[40+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[16] && reg_we) && (HMAC_PERMIT[36+:4] != (HMAC_PERMIT[36+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[17] && reg_we) && (HMAC_PERMIT[32+:4] != (HMAC_PERMIT[32+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[18] && reg_we) && (HMAC_PERMIT[28+:4] != (HMAC_PERMIT[28+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[19] && reg_we) && (HMAC_PERMIT[24+:4] != (HMAC_PERMIT[24+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[20] && reg_we) && (HMAC_PERMIT[20+:4] != (HMAC_PERMIT[20+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[21] && reg_we) && (HMAC_PERMIT[16+:4] != (HMAC_PERMIT[16+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[22] && reg_we) && (HMAC_PERMIT[12+:4] != (HMAC_PERMIT[12+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[23] && reg_we) && (HMAC_PERMIT[8+:4] != (HMAC_PERMIT[8+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[24] && reg_we) && (HMAC_PERMIT[4+:4] != (HMAC_PERMIT[4+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[25] && reg_we) && (HMAC_PERMIT[0+:4] != (HMAC_PERMIT[0+:4] & reg_be)))
			wr_err = 1'b1;
	end
	assign intr_state_hmac_done_we = (addr_hit[0] & reg_we) & ~wr_err;
	assign intr_state_hmac_done_wd = reg_wdata[0];
	assign intr_state_fifo_full_we = (addr_hit[0] & reg_we) & ~wr_err;
	assign intr_state_fifo_full_wd = reg_wdata[1];
	assign intr_state_hmac_err_we = (addr_hit[0] & reg_we) & ~wr_err;
	assign intr_state_hmac_err_wd = reg_wdata[2];
	assign intr_enable_hmac_done_we = (addr_hit[1] & reg_we) & ~wr_err;
	assign intr_enable_hmac_done_wd = reg_wdata[0];
	assign intr_enable_fifo_full_we = (addr_hit[1] & reg_we) & ~wr_err;
	assign intr_enable_fifo_full_wd = reg_wdata[1];
	assign intr_enable_hmac_err_we = (addr_hit[1] & reg_we) & ~wr_err;
	assign intr_enable_hmac_err_wd = reg_wdata[2];
	assign intr_test_hmac_done_we = (addr_hit[2] & reg_we) & ~wr_err;
	assign intr_test_hmac_done_wd = reg_wdata[0];
	assign intr_test_fifo_full_we = (addr_hit[2] & reg_we) & ~wr_err;
	assign intr_test_fifo_full_wd = reg_wdata[1];
	assign intr_test_hmac_err_we = (addr_hit[2] & reg_we) & ~wr_err;
	assign intr_test_hmac_err_wd = reg_wdata[2];
	assign cfg_hmac_en_we = (addr_hit[3] & reg_we) & ~wr_err;
	assign cfg_hmac_en_wd = reg_wdata[0];
	assign cfg_hmac_en_re = addr_hit[3] && reg_re;
	assign cfg_sha_en_we = (addr_hit[3] & reg_we) & ~wr_err;
	assign cfg_sha_en_wd = reg_wdata[1];
	assign cfg_sha_en_re = addr_hit[3] && reg_re;
	assign cfg_endian_swap_we = (addr_hit[3] & reg_we) & ~wr_err;
	assign cfg_endian_swap_wd = reg_wdata[2];
	assign cfg_endian_swap_re = addr_hit[3] && reg_re;
	assign cfg_digest_swap_we = (addr_hit[3] & reg_we) & ~wr_err;
	assign cfg_digest_swap_wd = reg_wdata[3];
	assign cfg_digest_swap_re = addr_hit[3] && reg_re;
	assign cmd_hash_start_we = (addr_hit[4] & reg_we) & ~wr_err;
	assign cmd_hash_start_wd = reg_wdata[0];
	assign cmd_hash_process_we = (addr_hit[4] & reg_we) & ~wr_err;
	assign cmd_hash_process_wd = reg_wdata[1];
	assign status_fifo_empty_re = addr_hit[5] && reg_re;
	assign status_fifo_full_re = addr_hit[5] && reg_re;
	assign status_fifo_depth_re = addr_hit[5] && reg_re;
	assign wipe_secret_we = (addr_hit[7] & reg_we) & ~wr_err;
	assign wipe_secret_wd = reg_wdata[31:0];
	assign key0_we = (addr_hit[8] & reg_we) & ~wr_err;
	assign key0_wd = reg_wdata[31:0];
	assign key1_we = (addr_hit[9] & reg_we) & ~wr_err;
	assign key1_wd = reg_wdata[31:0];
	assign key2_we = (addr_hit[10] & reg_we) & ~wr_err;
	assign key2_wd = reg_wdata[31:0];
	assign key3_we = (addr_hit[11] & reg_we) & ~wr_err;
	assign key3_wd = reg_wdata[31:0];
	assign key4_we = (addr_hit[12] & reg_we) & ~wr_err;
	assign key4_wd = reg_wdata[31:0];
	assign key5_we = (addr_hit[13] & reg_we) & ~wr_err;
	assign key5_wd = reg_wdata[31:0];
	assign key6_we = (addr_hit[14] & reg_we) & ~wr_err;
	assign key6_wd = reg_wdata[31:0];
	assign key7_we = (addr_hit[15] & reg_we) & ~wr_err;
	assign key7_wd = reg_wdata[31:0];
	assign digest0_re = addr_hit[16] && reg_re;
	assign digest1_re = addr_hit[17] && reg_re;
	assign digest2_re = addr_hit[18] && reg_re;
	assign digest3_re = addr_hit[19] && reg_re;
	assign digest4_re = addr_hit[20] && reg_re;
	assign digest5_re = addr_hit[21] && reg_re;
	assign digest6_re = addr_hit[22] && reg_re;
	assign digest7_re = addr_hit[23] && reg_re;
	always @(*) begin
		reg_rdata_next = 1'sb0;
		case (1'b1)
			addr_hit[0]: begin
				reg_rdata_next[0] = intr_state_hmac_done_qs;
				reg_rdata_next[1] = intr_state_fifo_full_qs;
				reg_rdata_next[2] = intr_state_hmac_err_qs;
			end
			addr_hit[1]: begin
				reg_rdata_next[0] = intr_enable_hmac_done_qs;
				reg_rdata_next[1] = intr_enable_fifo_full_qs;
				reg_rdata_next[2] = intr_enable_hmac_err_qs;
			end
			addr_hit[2]: begin
				reg_rdata_next[0] = 1'sb0;
				reg_rdata_next[1] = 1'sb0;
				reg_rdata_next[2] = 1'sb0;
			end
			addr_hit[3]: begin
				reg_rdata_next[0] = cfg_hmac_en_qs;
				reg_rdata_next[1] = cfg_sha_en_qs;
				reg_rdata_next[2] = cfg_endian_swap_qs;
				reg_rdata_next[3] = cfg_digest_swap_qs;
			end
			addr_hit[4]: begin
				reg_rdata_next[0] = 1'sb0;
				reg_rdata_next[1] = 1'sb0;
			end
			addr_hit[5]: begin
				reg_rdata_next[0] = status_fifo_empty_qs;
				reg_rdata_next[1] = status_fifo_full_qs;
				reg_rdata_next[8:4] = status_fifo_depth_qs;
			end
			addr_hit[6]: reg_rdata_next[31:0] = err_code_qs;
			addr_hit[7]: reg_rdata_next[31:0] = 1'sb0;
			addr_hit[8]: reg_rdata_next[31:0] = 1'sb0;
			addr_hit[9]: reg_rdata_next[31:0] = 1'sb0;
			addr_hit[10]: reg_rdata_next[31:0] = 1'sb0;
			addr_hit[11]: reg_rdata_next[31:0] = 1'sb0;
			addr_hit[12]: reg_rdata_next[31:0] = 1'sb0;
			addr_hit[13]: reg_rdata_next[31:0] = 1'sb0;
			addr_hit[14]: reg_rdata_next[31:0] = 1'sb0;
			addr_hit[15]: reg_rdata_next[31:0] = 1'sb0;
			addr_hit[16]: reg_rdata_next[31:0] = digest0_qs;
			addr_hit[17]: reg_rdata_next[31:0] = digest1_qs;
			addr_hit[18]: reg_rdata_next[31:0] = digest2_qs;
			addr_hit[19]: reg_rdata_next[31:0] = digest3_qs;
			addr_hit[20]: reg_rdata_next[31:0] = digest4_qs;
			addr_hit[21]: reg_rdata_next[31:0] = digest5_qs;
			addr_hit[22]: reg_rdata_next[31:0] = digest6_qs;
			addr_hit[23]: reg_rdata_next[31:0] = digest7_qs;
			addr_hit[24]: reg_rdata_next[31:0] = msg_length_lower_qs;
			addr_hit[25]: reg_rdata_next[31:0] = msg_length_upper_qs;
			default: reg_rdata_next = 1'sb1;
		endcase
	end
endmodule
