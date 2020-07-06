module flash_ctrl_reg_top (
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
	output wire [((((((7 + (($clog2($clog2(32 >> 3) + 1) - 1) >= 0 ? $clog2($clog2(32 >> 3) + 1) : 2 - $clog2($clog2(32 >> 3) + 1))) + 40) + (((32 >> 3) - 1) >= 0 ? 32 >> 3 : 2 - (32 >> 3))) + 49) - 1) >= 0 ? (2 * ((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_AW) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + top_pkg_TL_DW) + 17)) + -1 : (2 * (2 - ((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_AW) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + top_pkg_TL_DW) + 17))) + ((((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_AW) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + top_pkg_TL_DW) + 17) - 1) - 1)):((((((7 + (($clog2($clog2(32 >> 3) + 1) - 1) >= 0 ? $clog2($clog2(32 >> 3) + 1) : 2 - $clog2($clog2(32 >> 3) + 1))) + 40) + (((32 >> 3) - 1) >= 0 ? 32 >> 3 : 2 - (32 >> 3))) + 49) - 1) >= 0 ? 0 : ((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_AW) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + top_pkg_TL_DW) + 17) - 1)] tl_win_o;
	input wire [((((7 + (($clog2($clog2(32 >> 3) + 1) - 1) >= 0 ? $clog2($clog2(32 >> 3) + 1) : 2 - $clog2($clog2(32 >> 3) + 1))) + 59) - 1) >= 0 ? (2 * ((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_DIW) + top_pkg_TL_DW) + top_pkg_TL_DUW) + 2)) + -1 : (2 * (2 - ((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_DIW) + top_pkg_TL_DW) + top_pkg_TL_DUW) + 2))) + ((((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_DIW) + top_pkg_TL_DW) + top_pkg_TL_DUW) + 2) - 1) - 1)):((((7 + (($clog2($clog2(32 >> 3) + 1) - 1) >= 0 ? $clog2($clog2(32 >> 3) + 1) : 2 - $clog2($clog2(32 >> 3) + 1))) + 59) - 1) >= 0 ? 0 : ((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_DIW) + top_pkg_TL_DW) + top_pkg_TL_DUW) + 2) - 1)] tl_win_i;
	output wire [295:0] reg2hw;
	input wire [32:0] hw2reg;
	input devmode_i;
	parameter signed [31:0] NumBanks = 2;
	parameter signed [31:0] NumRegions = 8;
	parameter [6:0] FLASH_CTRL_INTR_STATE_OFFSET = 7'h 0;
	parameter [6:0] FLASH_CTRL_INTR_ENABLE_OFFSET = 7'h 4;
	parameter [6:0] FLASH_CTRL_INTR_TEST_OFFSET = 7'h 8;
	parameter [6:0] FLASH_CTRL_CONTROL_OFFSET = 7'h c;
	parameter [6:0] FLASH_CTRL_ADDR_OFFSET = 7'h 10;
	parameter [6:0] FLASH_CTRL_REGION_CFG_REGWEN_OFFSET = 7'h 14;
	parameter [6:0] FLASH_CTRL_MP_REGION_CFG0_OFFSET = 7'h 18;
	parameter [6:0] FLASH_CTRL_MP_REGION_CFG1_OFFSET = 7'h 1c;
	parameter [6:0] FLASH_CTRL_MP_REGION_CFG2_OFFSET = 7'h 20;
	parameter [6:0] FLASH_CTRL_MP_REGION_CFG3_OFFSET = 7'h 24;
	parameter [6:0] FLASH_CTRL_MP_REGION_CFG4_OFFSET = 7'h 28;
	parameter [6:0] FLASH_CTRL_MP_REGION_CFG5_OFFSET = 7'h 2c;
	parameter [6:0] FLASH_CTRL_MP_REGION_CFG6_OFFSET = 7'h 30;
	parameter [6:0] FLASH_CTRL_MP_REGION_CFG7_OFFSET = 7'h 34;
	parameter [6:0] FLASH_CTRL_DEFAULT_REGION_OFFSET = 7'h 38;
	parameter [6:0] FLASH_CTRL_BANK_CFG_REGWEN_OFFSET = 7'h 3c;
	parameter [6:0] FLASH_CTRL_MP_BANK_CFG_OFFSET = 7'h 40;
	parameter [6:0] FLASH_CTRL_OP_STATUS_OFFSET = 7'h 44;
	parameter [6:0] FLASH_CTRL_STATUS_OFFSET = 7'h 48;
	parameter [6:0] FLASH_CTRL_SCRATCH_OFFSET = 7'h 4c;
	parameter [6:0] FLASH_CTRL_FIFO_LVL_OFFSET = 7'h 50;
	parameter [6:0] FLASH_CTRL_PROG_FIFO_OFFSET = 7'h 54;
	parameter [6:0] FLASH_CTRL_PROG_FIFO_SIZE = 7'h 4;
	parameter [6:0] FLASH_CTRL_RD_FIFO_OFFSET = 7'h 58;
	parameter [6:0] FLASH_CTRL_RD_FIFO_SIZE = 7'h 4;
	parameter [83:0] FLASH_CTRL_PERMIT = {4'b 0001, 4'b 0001, 4'b 0001, 4'b 1111, 4'b 1111, 4'b 0001, 4'b 1111, 4'b 1111, 4'b 1111, 4'b 1111, 4'b 1111, 4'b 1111, 4'b 1111, 4'b 1111, 4'b 0001, 4'b 0001, 4'b 0001, 4'b 0001, 4'b 0111, 4'b 1111, 4'b 0011};
	localparam FLASH_CTRL_INTR_STATE = 0;
	localparam FLASH_CTRL_INTR_ENABLE = 1;
	localparam FLASH_CTRL_MP_REGION_CFG4 = 10;
	localparam FLASH_CTRL_MP_REGION_CFG5 = 11;
	localparam FLASH_CTRL_MP_REGION_CFG6 = 12;
	localparam FLASH_CTRL_MP_REGION_CFG7 = 13;
	localparam FLASH_CTRL_DEFAULT_REGION = 14;
	localparam FLASH_CTRL_BANK_CFG_REGWEN = 15;
	localparam FLASH_CTRL_MP_BANK_CFG = 16;
	localparam FLASH_CTRL_OP_STATUS = 17;
	localparam FLASH_CTRL_STATUS = 18;
	localparam FLASH_CTRL_SCRATCH = 19;
	localparam FLASH_CTRL_INTR_TEST = 2;
	localparam FLASH_CTRL_FIFO_LVL = 20;
	localparam FLASH_CTRL_CONTROL = 3;
	localparam FLASH_CTRL_ADDR = 4;
	localparam FLASH_CTRL_REGION_CFG_REGWEN = 5;
	localparam FLASH_CTRL_MP_REGION_CFG0 = 6;
	localparam FLASH_CTRL_MP_REGION_CFG1 = 7;
	localparam FLASH_CTRL_MP_REGION_CFG2 = 8;
	localparam FLASH_CTRL_MP_REGION_CFG3 = 9;
	localparam signed [31:0] AW = 7;
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
	wire [((((((7 + (($clog2($clog2(32 >> 3) + 1) - 1) >= 0 ? $clog2($clog2(32 >> 3) + 1) : 2 - $clog2($clog2(32 >> 3) + 1))) + 40) + (((32 >> 3) - 1) >= 0 ? 32 >> 3 : 2 - (32 >> 3))) + 49) - 1) >= 0 ? (3 * ((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_AW) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + top_pkg_TL_DW) + 17)) + -1 : (3 * (2 - ((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_AW) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + top_pkg_TL_DW) + 17))) + ((((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_AW) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + top_pkg_TL_DW) + 17) - 1) - 1)):((((((7 + (($clog2($clog2(32 >> 3) + 1) - 1) >= 0 ? $clog2($clog2(32 >> 3) + 1) : 2 - $clog2($clog2(32 >> 3) + 1))) + 40) + (((32 >> 3) - 1) >= 0 ? 32 >> 3 : 2 - (32 >> 3))) + 49) - 1) >= 0 ? 0 : ((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_AW) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + top_pkg_TL_DW) + 17) - 1)] tl_socket_h2d;
	wire [((((7 + (($clog2($clog2(32 >> 3) + 1) - 1) >= 0 ? $clog2($clog2(32 >> 3) + 1) : 2 - $clog2($clog2(32 >> 3) + 1))) + 59) - 1) >= 0 ? (3 * ((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_DIW) + top_pkg_TL_DW) + top_pkg_TL_DUW) + 2)) + -1 : (3 * (2 - ((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_DIW) + top_pkg_TL_DW) + top_pkg_TL_DUW) + 2))) + ((((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_DIW) + top_pkg_TL_DW) + top_pkg_TL_DUW) + 2) - 1) - 1)):((((7 + (($clog2($clog2(32 >> 3) + 1) - 1) >= 0 ? $clog2($clog2(32 >> 3) + 1) : 2 - $clog2($clog2(32 >> 3) + 1))) + 59) - 1) >= 0 ? 0 : ((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_DIW) + top_pkg_TL_DW) + top_pkg_TL_DUW) + 2) - 1)] tl_socket_d2h;
	reg [1:0] reg_steer;
	assign tl_reg_h2d = tl_socket_h2d[((((((7 + (($clog2($clog2(32 >> 3) + 1) - 1) >= 0 ? $clog2($clog2(32 >> 3) + 1) : 2 - $clog2($clog2(32 >> 3) + 1))) + 40) + (((32 >> 3) - 1) >= 0 ? 32 >> 3 : 2 - (32 >> 3))) + 49) - 1) >= 0 ? 0 : ((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_AW) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + top_pkg_TL_DW) + 17) - 1)+:((((((7 + (($clog2($clog2(32 >> 3) + 1) - 1) >= 0 ? $clog2($clog2(32 >> 3) + 1) : 2 - $clog2($clog2(32 >> 3) + 1))) + 40) + (((32 >> 3) - 1) >= 0 ? 32 >> 3 : 2 - (32 >> 3))) + 49) - 1) >= 0 ? (((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_AW) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + top_pkg_TL_DW) + 17 : 2 - ((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_AW) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + top_pkg_TL_DW) + 17))];
	assign tl_socket_d2h[((((7 + (($clog2($clog2(32 >> 3) + 1) - 1) >= 0 ? $clog2($clog2(32 >> 3) + 1) : 2 - $clog2($clog2(32 >> 3) + 1))) + 59) - 1) >= 0 ? 0 : ((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_DIW) + top_pkg_TL_DW) + top_pkg_TL_DUW) + 2) - 1)+:((((7 + (($clog2($clog2(32 >> 3) + 1) - 1) >= 0 ? $clog2($clog2(32 >> 3) + 1) : 2 - $clog2($clog2(32 >> 3) + 1))) + 59) - 1) >= 0 ? (((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_DIW) + top_pkg_TL_DW) + top_pkg_TL_DUW) + 2 : 2 - ((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_DIW) + top_pkg_TL_DW) + top_pkg_TL_DUW) + 2))] = tl_reg_d2h;
	assign tl_win_o[((((((7 + (($clog2($clog2(32 >> 3) + 1) - 1) >= 0 ? $clog2($clog2(32 >> 3) + 1) : 2 - $clog2($clog2(32 >> 3) + 1))) + 40) + (((32 >> 3) - 1) >= 0 ? 32 >> 3 : 2 - (32 >> 3))) + 49) - 1) >= 0 ? 0 : ((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_AW) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + top_pkg_TL_DW) + 17) - 1) + ((((((7 + (($clog2($clog2(32 >> 3) + 1) - 1) >= 0 ? $clog2($clog2(32 >> 3) + 1) : 2 - $clog2($clog2(32 >> 3) + 1))) + 40) + (((32 >> 3) - 1) >= 0 ? 32 >> 3 : 2 - (32 >> 3))) + 49) - 1) >= 0 ? (((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_AW) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + top_pkg_TL_DW) + 17 : 2 - ((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_AW) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + top_pkg_TL_DW) + 17))+:((((((7 + (($clog2($clog2(32 >> 3) + 1) - 1) >= 0 ? $clog2($clog2(32 >> 3) + 1) : 2 - $clog2($clog2(32 >> 3) + 1))) + 40) + (((32 >> 3) - 1) >= 0 ? 32 >> 3 : 2 - (32 >> 3))) + 49) - 1) >= 0 ? (((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_AW) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + top_pkg_TL_DW) + 17 : 2 - ((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_AW) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + top_pkg_TL_DW) + 17))] = tl_socket_h2d[((((((7 + (($clog2($clog2(32 >> 3) + 1) - 1) >= 0 ? $clog2($clog2(32 >> 3) + 1) : 2 - $clog2($clog2(32 >> 3) + 1))) + 40) + (((32 >> 3) - 1) >= 0 ? 32 >> 3 : 2 - (32 >> 3))) + 49) - 1) >= 0 ? 0 : ((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_AW) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + top_pkg_TL_DW) + 17) - 1) + (2 * ((((((7 + (($clog2($clog2(32 >> 3) + 1) - 1) >= 0 ? $clog2($clog2(32 >> 3) + 1) : 2 - $clog2($clog2(32 >> 3) + 1))) + 40) + (((32 >> 3) - 1) >= 0 ? 32 >> 3 : 2 - (32 >> 3))) + 49) - 1) >= 0 ? (((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_AW) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + top_pkg_TL_DW) + 17 : 2 - ((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_AW) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + top_pkg_TL_DW) + 17)))+:((((((7 + (($clog2($clog2(32 >> 3) + 1) - 1) >= 0 ? $clog2($clog2(32 >> 3) + 1) : 2 - $clog2($clog2(32 >> 3) + 1))) + 40) + (((32 >> 3) - 1) >= 0 ? 32 >> 3 : 2 - (32 >> 3))) + 49) - 1) >= 0 ? (((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_AW) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + top_pkg_TL_DW) + 17 : 2 - ((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_AW) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + top_pkg_TL_DW) + 17))];
	assign tl_socket_d2h[((((7 + (($clog2($clog2(32 >> 3) + 1) - 1) >= 0 ? $clog2($clog2(32 >> 3) + 1) : 2 - $clog2($clog2(32 >> 3) + 1))) + 59) - 1) >= 0 ? 0 : ((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_DIW) + top_pkg_TL_DW) + top_pkg_TL_DUW) + 2) - 1) + (2 * ((((7 + (($clog2($clog2(32 >> 3) + 1) - 1) >= 0 ? $clog2($clog2(32 >> 3) + 1) : 2 - $clog2($clog2(32 >> 3) + 1))) + 59) - 1) >= 0 ? (((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_DIW) + top_pkg_TL_DW) + top_pkg_TL_DUW) + 2 : 2 - ((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_DIW) + top_pkg_TL_DW) + top_pkg_TL_DUW) + 2)))+:((((7 + (($clog2($clog2(32 >> 3) + 1) - 1) >= 0 ? $clog2($clog2(32 >> 3) + 1) : 2 - $clog2($clog2(32 >> 3) + 1))) + 59) - 1) >= 0 ? (((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_DIW) + top_pkg_TL_DW) + top_pkg_TL_DUW) + 2 : 2 - ((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_DIW) + top_pkg_TL_DW) + top_pkg_TL_DUW) + 2))] = tl_win_i[((((7 + (($clog2($clog2(32 >> 3) + 1) - 1) >= 0 ? $clog2($clog2(32 >> 3) + 1) : 2 - $clog2($clog2(32 >> 3) + 1))) + 59) - 1) >= 0 ? 0 : ((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_DIW) + top_pkg_TL_DW) + top_pkg_TL_DUW) + 2) - 1) + ((((7 + (($clog2($clog2(32 >> 3) + 1) - 1) >= 0 ? $clog2($clog2(32 >> 3) + 1) : 2 - $clog2($clog2(32 >> 3) + 1))) + 59) - 1) >= 0 ? (((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_DIW) + top_pkg_TL_DW) + top_pkg_TL_DUW) + 2 : 2 - ((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_DIW) + top_pkg_TL_DW) + top_pkg_TL_DUW) + 2))+:((((7 + (($clog2($clog2(32 >> 3) + 1) - 1) >= 0 ? $clog2($clog2(32 >> 3) + 1) : 2 - $clog2($clog2(32 >> 3) + 1))) + 59) - 1) >= 0 ? (((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_DIW) + top_pkg_TL_DW) + top_pkg_TL_DUW) + 2 : 2 - ((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_DIW) + top_pkg_TL_DW) + top_pkg_TL_DUW) + 2))];
	assign tl_win_o[((((((7 + (($clog2($clog2(32 >> 3) + 1) - 1) >= 0 ? $clog2($clog2(32 >> 3) + 1) : 2 - $clog2($clog2(32 >> 3) + 1))) + 40) + (((32 >> 3) - 1) >= 0 ? 32 >> 3 : 2 - (32 >> 3))) + 49) - 1) >= 0 ? 0 : ((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_AW) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + top_pkg_TL_DW) + 17) - 1)+:((((((7 + (($clog2($clog2(32 >> 3) + 1) - 1) >= 0 ? $clog2($clog2(32 >> 3) + 1) : 2 - $clog2($clog2(32 >> 3) + 1))) + 40) + (((32 >> 3) - 1) >= 0 ? 32 >> 3 : 2 - (32 >> 3))) + 49) - 1) >= 0 ? (((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_AW) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + top_pkg_TL_DW) + 17 : 2 - ((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_AW) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + top_pkg_TL_DW) + 17))] = tl_socket_h2d[((((((7 + (($clog2($clog2(32 >> 3) + 1) - 1) >= 0 ? $clog2($clog2(32 >> 3) + 1) : 2 - $clog2($clog2(32 >> 3) + 1))) + 40) + (((32 >> 3) - 1) >= 0 ? 32 >> 3 : 2 - (32 >> 3))) + 49) - 1) >= 0 ? 0 : ((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_AW) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + top_pkg_TL_DW) + 17) - 1) + ((((((7 + (($clog2($clog2(32 >> 3) + 1) - 1) >= 0 ? $clog2($clog2(32 >> 3) + 1) : 2 - $clog2($clog2(32 >> 3) + 1))) + 40) + (((32 >> 3) - 1) >= 0 ? 32 >> 3 : 2 - (32 >> 3))) + 49) - 1) >= 0 ? (((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_AW) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + top_pkg_TL_DW) + 17 : 2 - ((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_AW) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + top_pkg_TL_DW) + 17))+:((((((7 + (($clog2($clog2(32 >> 3) + 1) - 1) >= 0 ? $clog2($clog2(32 >> 3) + 1) : 2 - $clog2($clog2(32 >> 3) + 1))) + 40) + (((32 >> 3) - 1) >= 0 ? 32 >> 3 : 2 - (32 >> 3))) + 49) - 1) >= 0 ? (((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_AW) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + top_pkg_TL_DW) + 17 : 2 - ((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_AW) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + top_pkg_TL_DW) + 17))];
	assign tl_socket_d2h[((((7 + (($clog2($clog2(32 >> 3) + 1) - 1) >= 0 ? $clog2($clog2(32 >> 3) + 1) : 2 - $clog2($clog2(32 >> 3) + 1))) + 59) - 1) >= 0 ? 0 : ((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_DIW) + top_pkg_TL_DW) + top_pkg_TL_DUW) + 2) - 1) + ((((7 + (($clog2($clog2(32 >> 3) + 1) - 1) >= 0 ? $clog2($clog2(32 >> 3) + 1) : 2 - $clog2($clog2(32 >> 3) + 1))) + 59) - 1) >= 0 ? (((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_DIW) + top_pkg_TL_DW) + top_pkg_TL_DUW) + 2 : 2 - ((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_DIW) + top_pkg_TL_DW) + top_pkg_TL_DUW) + 2))+:((((7 + (($clog2($clog2(32 >> 3) + 1) - 1) >= 0 ? $clog2($clog2(32 >> 3) + 1) : 2 - $clog2($clog2(32 >> 3) + 1))) + 59) - 1) >= 0 ? (((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_DIW) + top_pkg_TL_DW) + top_pkg_TL_DUW) + 2 : 2 - ((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_DIW) + top_pkg_TL_DW) + top_pkg_TL_DUW) + 2))] = tl_win_i[((((7 + (($clog2($clog2(32 >> 3) + 1) - 1) >= 0 ? $clog2($clog2(32 >> 3) + 1) : 2 - $clog2($clog2(32 >> 3) + 1))) + 59) - 1) >= 0 ? 0 : ((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_DIW) + top_pkg_TL_DW) + top_pkg_TL_DUW) + 2) - 1)+:((((7 + (($clog2($clog2(32 >> 3) + 1) - 1) >= 0 ? $clog2($clog2(32 >> 3) + 1) : 2 - $clog2($clog2(32 >> 3) + 1))) + 59) - 1) >= 0 ? (((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_DIW) + top_pkg_TL_DW) + top_pkg_TL_DUW) + 2 : 2 - ((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_DIW) + top_pkg_TL_DW) + top_pkg_TL_DUW) + 2))];
	tlul_socket_1n #(
		.N(3),
		.HReqPass(1'b1),
		.HRspPass(1'b1),
		.DReqPass({3 {1'b1}}),
		.DRspPass({3 {1'b1}}),
		.HReqDepth(4'h0),
		.HRspDepth(4'h0),
		.DReqDepth({3 {4'h0}}),
		.DRspDepth({3 {4'h0}})
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
		reg_steer = 2;
		if ((tl_i[(top_pkg_TL_AW + (((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW) + (top_pkg_TL_DW + 16))) - ((top_pkg_TL_AW - 1) - (AW - 1)):(top_pkg_TL_AW + (((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW) + (top_pkg_TL_DW + 16))) - (top_pkg_TL_AW - 1)] >= 84) && (tl_i[(top_pkg_TL_AW + (((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW) + (top_pkg_TL_DW + 16))) - ((top_pkg_TL_AW - 1) - (AW - 1)):(top_pkg_TL_AW + (((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW) + (top_pkg_TL_DW + 16))) - (top_pkg_TL_AW - 1)] < 88))
			reg_steer = 0;
		if ((tl_i[(top_pkg_TL_AW + (((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW) + (top_pkg_TL_DW + 16))) - ((top_pkg_TL_AW - 1) - (AW - 1)):(top_pkg_TL_AW + (((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW) + (top_pkg_TL_DW + 16))) - (top_pkg_TL_AW - 1)] >= 88) && (tl_i[(top_pkg_TL_AW + (((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW) + (top_pkg_TL_DW + 16))) - ((top_pkg_TL_AW - 1) - (AW - 1)):(top_pkg_TL_AW + (((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW) + (top_pkg_TL_DW + 16))) - (top_pkg_TL_AW - 1)] < 92))
			reg_steer = 1;
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
	wire intr_state_prog_empty_qs;
	wire intr_state_prog_empty_wd;
	wire intr_state_prog_empty_we;
	wire intr_state_prog_lvl_qs;
	wire intr_state_prog_lvl_wd;
	wire intr_state_prog_lvl_we;
	wire intr_state_rd_full_qs;
	wire intr_state_rd_full_wd;
	wire intr_state_rd_full_we;
	wire intr_state_rd_lvl_qs;
	wire intr_state_rd_lvl_wd;
	wire intr_state_rd_lvl_we;
	wire intr_state_op_done_qs;
	wire intr_state_op_done_wd;
	wire intr_state_op_done_we;
	wire intr_state_op_error_qs;
	wire intr_state_op_error_wd;
	wire intr_state_op_error_we;
	wire intr_enable_prog_empty_qs;
	wire intr_enable_prog_empty_wd;
	wire intr_enable_prog_empty_we;
	wire intr_enable_prog_lvl_qs;
	wire intr_enable_prog_lvl_wd;
	wire intr_enable_prog_lvl_we;
	wire intr_enable_rd_full_qs;
	wire intr_enable_rd_full_wd;
	wire intr_enable_rd_full_we;
	wire intr_enable_rd_lvl_qs;
	wire intr_enable_rd_lvl_wd;
	wire intr_enable_rd_lvl_we;
	wire intr_enable_op_done_qs;
	wire intr_enable_op_done_wd;
	wire intr_enable_op_done_we;
	wire intr_enable_op_error_qs;
	wire intr_enable_op_error_wd;
	wire intr_enable_op_error_we;
	wire intr_test_prog_empty_wd;
	wire intr_test_prog_empty_we;
	wire intr_test_prog_lvl_wd;
	wire intr_test_prog_lvl_we;
	wire intr_test_rd_full_wd;
	wire intr_test_rd_full_we;
	wire intr_test_rd_lvl_wd;
	wire intr_test_rd_lvl_we;
	wire intr_test_op_done_wd;
	wire intr_test_op_done_we;
	wire intr_test_op_error_wd;
	wire intr_test_op_error_we;
	wire control_start_qs;
	wire control_start_wd;
	wire control_start_we;
	wire [1:0] control_op_qs;
	wire [1:0] control_op_wd;
	wire control_op_we;
	wire control_erase_sel_qs;
	wire control_erase_sel_wd;
	wire control_erase_sel_we;
	wire control_fifo_rst_qs;
	wire control_fifo_rst_wd;
	wire control_fifo_rst_we;
	wire [11:0] control_num_qs;
	wire [11:0] control_num_wd;
	wire control_num_we;
	wire [31:0] addr_qs;
	wire [31:0] addr_wd;
	wire addr_we;
	wire region_cfg_regwen_qs;
	wire region_cfg_regwen_wd;
	wire region_cfg_regwen_we;
	wire mp_region_cfg0_en0_qs;
	wire mp_region_cfg0_en0_wd;
	wire mp_region_cfg0_en0_we;
	wire mp_region_cfg0_rd_en0_qs;
	wire mp_region_cfg0_rd_en0_wd;
	wire mp_region_cfg0_rd_en0_we;
	wire mp_region_cfg0_prog_en0_qs;
	wire mp_region_cfg0_prog_en0_wd;
	wire mp_region_cfg0_prog_en0_we;
	wire mp_region_cfg0_erase_en0_qs;
	wire mp_region_cfg0_erase_en0_wd;
	wire mp_region_cfg0_erase_en0_we;
	wire [8:0] mp_region_cfg0_base0_qs;
	wire [8:0] mp_region_cfg0_base0_wd;
	wire mp_region_cfg0_base0_we;
	wire [8:0] mp_region_cfg0_size0_qs;
	wire [8:0] mp_region_cfg0_size0_wd;
	wire mp_region_cfg0_size0_we;
	wire mp_region_cfg1_en1_qs;
	wire mp_region_cfg1_en1_wd;
	wire mp_region_cfg1_en1_we;
	wire mp_region_cfg1_rd_en1_qs;
	wire mp_region_cfg1_rd_en1_wd;
	wire mp_region_cfg1_rd_en1_we;
	wire mp_region_cfg1_prog_en1_qs;
	wire mp_region_cfg1_prog_en1_wd;
	wire mp_region_cfg1_prog_en1_we;
	wire mp_region_cfg1_erase_en1_qs;
	wire mp_region_cfg1_erase_en1_wd;
	wire mp_region_cfg1_erase_en1_we;
	wire [8:0] mp_region_cfg1_base1_qs;
	wire [8:0] mp_region_cfg1_base1_wd;
	wire mp_region_cfg1_base1_we;
	wire [8:0] mp_region_cfg1_size1_qs;
	wire [8:0] mp_region_cfg1_size1_wd;
	wire mp_region_cfg1_size1_we;
	wire mp_region_cfg2_en2_qs;
	wire mp_region_cfg2_en2_wd;
	wire mp_region_cfg2_en2_we;
	wire mp_region_cfg2_rd_en2_qs;
	wire mp_region_cfg2_rd_en2_wd;
	wire mp_region_cfg2_rd_en2_we;
	wire mp_region_cfg2_prog_en2_qs;
	wire mp_region_cfg2_prog_en2_wd;
	wire mp_region_cfg2_prog_en2_we;
	wire mp_region_cfg2_erase_en2_qs;
	wire mp_region_cfg2_erase_en2_wd;
	wire mp_region_cfg2_erase_en2_we;
	wire [8:0] mp_region_cfg2_base2_qs;
	wire [8:0] mp_region_cfg2_base2_wd;
	wire mp_region_cfg2_base2_we;
	wire [8:0] mp_region_cfg2_size2_qs;
	wire [8:0] mp_region_cfg2_size2_wd;
	wire mp_region_cfg2_size2_we;
	wire mp_region_cfg3_en3_qs;
	wire mp_region_cfg3_en3_wd;
	wire mp_region_cfg3_en3_we;
	wire mp_region_cfg3_rd_en3_qs;
	wire mp_region_cfg3_rd_en3_wd;
	wire mp_region_cfg3_rd_en3_we;
	wire mp_region_cfg3_prog_en3_qs;
	wire mp_region_cfg3_prog_en3_wd;
	wire mp_region_cfg3_prog_en3_we;
	wire mp_region_cfg3_erase_en3_qs;
	wire mp_region_cfg3_erase_en3_wd;
	wire mp_region_cfg3_erase_en3_we;
	wire [8:0] mp_region_cfg3_base3_qs;
	wire [8:0] mp_region_cfg3_base3_wd;
	wire mp_region_cfg3_base3_we;
	wire [8:0] mp_region_cfg3_size3_qs;
	wire [8:0] mp_region_cfg3_size3_wd;
	wire mp_region_cfg3_size3_we;
	wire mp_region_cfg4_en4_qs;
	wire mp_region_cfg4_en4_wd;
	wire mp_region_cfg4_en4_we;
	wire mp_region_cfg4_rd_en4_qs;
	wire mp_region_cfg4_rd_en4_wd;
	wire mp_region_cfg4_rd_en4_we;
	wire mp_region_cfg4_prog_en4_qs;
	wire mp_region_cfg4_prog_en4_wd;
	wire mp_region_cfg4_prog_en4_we;
	wire mp_region_cfg4_erase_en4_qs;
	wire mp_region_cfg4_erase_en4_wd;
	wire mp_region_cfg4_erase_en4_we;
	wire [8:0] mp_region_cfg4_base4_qs;
	wire [8:0] mp_region_cfg4_base4_wd;
	wire mp_region_cfg4_base4_we;
	wire [8:0] mp_region_cfg4_size4_qs;
	wire [8:0] mp_region_cfg4_size4_wd;
	wire mp_region_cfg4_size4_we;
	wire mp_region_cfg5_en5_qs;
	wire mp_region_cfg5_en5_wd;
	wire mp_region_cfg5_en5_we;
	wire mp_region_cfg5_rd_en5_qs;
	wire mp_region_cfg5_rd_en5_wd;
	wire mp_region_cfg5_rd_en5_we;
	wire mp_region_cfg5_prog_en5_qs;
	wire mp_region_cfg5_prog_en5_wd;
	wire mp_region_cfg5_prog_en5_we;
	wire mp_region_cfg5_erase_en5_qs;
	wire mp_region_cfg5_erase_en5_wd;
	wire mp_region_cfg5_erase_en5_we;
	wire [8:0] mp_region_cfg5_base5_qs;
	wire [8:0] mp_region_cfg5_base5_wd;
	wire mp_region_cfg5_base5_we;
	wire [8:0] mp_region_cfg5_size5_qs;
	wire [8:0] mp_region_cfg5_size5_wd;
	wire mp_region_cfg5_size5_we;
	wire mp_region_cfg6_en6_qs;
	wire mp_region_cfg6_en6_wd;
	wire mp_region_cfg6_en6_we;
	wire mp_region_cfg6_rd_en6_qs;
	wire mp_region_cfg6_rd_en6_wd;
	wire mp_region_cfg6_rd_en6_we;
	wire mp_region_cfg6_prog_en6_qs;
	wire mp_region_cfg6_prog_en6_wd;
	wire mp_region_cfg6_prog_en6_we;
	wire mp_region_cfg6_erase_en6_qs;
	wire mp_region_cfg6_erase_en6_wd;
	wire mp_region_cfg6_erase_en6_we;
	wire [8:0] mp_region_cfg6_base6_qs;
	wire [8:0] mp_region_cfg6_base6_wd;
	wire mp_region_cfg6_base6_we;
	wire [8:0] mp_region_cfg6_size6_qs;
	wire [8:0] mp_region_cfg6_size6_wd;
	wire mp_region_cfg6_size6_we;
	wire mp_region_cfg7_en7_qs;
	wire mp_region_cfg7_en7_wd;
	wire mp_region_cfg7_en7_we;
	wire mp_region_cfg7_rd_en7_qs;
	wire mp_region_cfg7_rd_en7_wd;
	wire mp_region_cfg7_rd_en7_we;
	wire mp_region_cfg7_prog_en7_qs;
	wire mp_region_cfg7_prog_en7_wd;
	wire mp_region_cfg7_prog_en7_we;
	wire mp_region_cfg7_erase_en7_qs;
	wire mp_region_cfg7_erase_en7_wd;
	wire mp_region_cfg7_erase_en7_we;
	wire [8:0] mp_region_cfg7_base7_qs;
	wire [8:0] mp_region_cfg7_base7_wd;
	wire mp_region_cfg7_base7_we;
	wire [8:0] mp_region_cfg7_size7_qs;
	wire [8:0] mp_region_cfg7_size7_wd;
	wire mp_region_cfg7_size7_we;
	wire default_region_rd_en_qs;
	wire default_region_rd_en_wd;
	wire default_region_rd_en_we;
	wire default_region_prog_en_qs;
	wire default_region_prog_en_wd;
	wire default_region_prog_en_we;
	wire default_region_erase_en_qs;
	wire default_region_erase_en_wd;
	wire default_region_erase_en_we;
	wire bank_cfg_regwen_qs;
	wire bank_cfg_regwen_wd;
	wire bank_cfg_regwen_we;
	wire mp_bank_cfg_erase_en0_qs;
	wire mp_bank_cfg_erase_en0_wd;
	wire mp_bank_cfg_erase_en0_we;
	wire mp_bank_cfg_erase_en1_qs;
	wire mp_bank_cfg_erase_en1_wd;
	wire mp_bank_cfg_erase_en1_we;
	wire op_status_done_qs;
	wire op_status_done_wd;
	wire op_status_done_we;
	wire op_status_err_qs;
	wire op_status_err_wd;
	wire op_status_err_we;
	wire status_rd_full_qs;
	wire status_rd_full_re;
	wire status_rd_empty_qs;
	wire status_rd_empty_re;
	wire status_prog_full_qs;
	wire status_prog_full_re;
	wire status_prog_empty_qs;
	wire status_prog_empty_re;
	wire status_init_wip_qs;
	wire status_init_wip_re;
	wire [8:0] status_error_page_qs;
	wire status_error_page_re;
	wire status_error_bank_qs;
	wire status_error_bank_re;
	wire [31:0] scratch_qs;
	wire [31:0] scratch_wd;
	wire scratch_we;
	wire [4:0] fifo_lvl_prog_qs;
	wire [4:0] fifo_lvl_prog_wd;
	wire fifo_lvl_prog_we;
	wire [4:0] fifo_lvl_rd_qs;
	wire [4:0] fifo_lvl_rd_wd;
	wire fifo_lvl_rd_we;
	prim_subreg #(
		.DW(1),
		.SWACCESS("W1C"),
		.RESVAL(1'h0)
	) u_intr_state_prog_empty(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(intr_state_prog_empty_we),
		.wd(intr_state_prog_empty_wd),
		.de(hw2reg[31]),
		.d(hw2reg[32]),
		.qe(),
		.q(reg2hw[295]),
		.qs(intr_state_prog_empty_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("W1C"),
		.RESVAL(1'h0)
	) u_intr_state_prog_lvl(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(intr_state_prog_lvl_we),
		.wd(intr_state_prog_lvl_wd),
		.de(hw2reg[29]),
		.d(hw2reg[30]),
		.qe(),
		.q(reg2hw[294]),
		.qs(intr_state_prog_lvl_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("W1C"),
		.RESVAL(1'h0)
	) u_intr_state_rd_full(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(intr_state_rd_full_we),
		.wd(intr_state_rd_full_wd),
		.de(hw2reg[27]),
		.d(hw2reg[28]),
		.qe(),
		.q(reg2hw[293]),
		.qs(intr_state_rd_full_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("W1C"),
		.RESVAL(1'h0)
	) u_intr_state_rd_lvl(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(intr_state_rd_lvl_we),
		.wd(intr_state_rd_lvl_wd),
		.de(hw2reg[25]),
		.d(hw2reg[26]),
		.qe(),
		.q(reg2hw[292]),
		.qs(intr_state_rd_lvl_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("W1C"),
		.RESVAL(1'h0)
	) u_intr_state_op_done(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(intr_state_op_done_we),
		.wd(intr_state_op_done_wd),
		.de(hw2reg[23]),
		.d(hw2reg[24]),
		.qe(),
		.q(reg2hw[291]),
		.qs(intr_state_op_done_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("W1C"),
		.RESVAL(1'h0)
	) u_intr_state_op_error(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(intr_state_op_error_we),
		.wd(intr_state_op_error_wd),
		.de(hw2reg[21]),
		.d(hw2reg[22]),
		.qe(),
		.q(reg2hw[290]),
		.qs(intr_state_op_error_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_intr_enable_prog_empty(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(intr_enable_prog_empty_we),
		.wd(intr_enable_prog_empty_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[289]),
		.qs(intr_enable_prog_empty_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_intr_enable_prog_lvl(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(intr_enable_prog_lvl_we),
		.wd(intr_enable_prog_lvl_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[288]),
		.qs(intr_enable_prog_lvl_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_intr_enable_rd_full(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(intr_enable_rd_full_we),
		.wd(intr_enable_rd_full_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[287]),
		.qs(intr_enable_rd_full_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_intr_enable_rd_lvl(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(intr_enable_rd_lvl_we),
		.wd(intr_enable_rd_lvl_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[286]),
		.qs(intr_enable_rd_lvl_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_intr_enable_op_done(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(intr_enable_op_done_we),
		.wd(intr_enable_op_done_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[285]),
		.qs(intr_enable_op_done_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_intr_enable_op_error(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(intr_enable_op_error_we),
		.wd(intr_enable_op_error_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[284]),
		.qs(intr_enable_op_error_qs)
	);
	prim_subreg_ext #(.DW(1)) u_intr_test_prog_empty(
		.re(1'b0),
		.we(intr_test_prog_empty_we),
		.wd(intr_test_prog_empty_wd),
		.d(1'sb0),
		.qre(),
		.qe(reg2hw[282]),
		.q(reg2hw[283]),
		.qs()
	);
	prim_subreg_ext #(.DW(1)) u_intr_test_prog_lvl(
		.re(1'b0),
		.we(intr_test_prog_lvl_we),
		.wd(intr_test_prog_lvl_wd),
		.d(1'sb0),
		.qre(),
		.qe(reg2hw[280]),
		.q(reg2hw[281]),
		.qs()
	);
	prim_subreg_ext #(.DW(1)) u_intr_test_rd_full(
		.re(1'b0),
		.we(intr_test_rd_full_we),
		.wd(intr_test_rd_full_wd),
		.d(1'sb0),
		.qre(),
		.qe(reg2hw[278]),
		.q(reg2hw[279]),
		.qs()
	);
	prim_subreg_ext #(.DW(1)) u_intr_test_rd_lvl(
		.re(1'b0),
		.we(intr_test_rd_lvl_we),
		.wd(intr_test_rd_lvl_wd),
		.d(1'sb0),
		.qre(),
		.qe(reg2hw[276]),
		.q(reg2hw[277]),
		.qs()
	);
	prim_subreg_ext #(.DW(1)) u_intr_test_op_done(
		.re(1'b0),
		.we(intr_test_op_done_we),
		.wd(intr_test_op_done_wd),
		.d(1'sb0),
		.qre(),
		.qe(reg2hw[274]),
		.q(reg2hw[275]),
		.qs()
	);
	prim_subreg_ext #(.DW(1)) u_intr_test_op_error(
		.re(1'b0),
		.we(intr_test_op_error_we),
		.wd(intr_test_op_error_wd),
		.d(1'sb0),
		.qre(),
		.qe(reg2hw[272]),
		.q(reg2hw[273]),
		.qs()
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_control_start(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(control_start_we),
		.wd(control_start_wd),
		.de(hw2reg[19]),
		.d(hw2reg[20]),
		.qe(),
		.q(reg2hw[271]),
		.qs(control_start_qs)
	);
	prim_subreg #(
		.DW(2),
		.SWACCESS("RW"),
		.RESVAL(2'h0)
	) u_control_op(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(control_op_we),
		.wd(control_op_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[270-:2]),
		.qs(control_op_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_control_erase_sel(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(control_erase_sel_we),
		.wd(control_erase_sel_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[268]),
		.qs(control_erase_sel_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_control_fifo_rst(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(control_fifo_rst_we),
		.wd(control_fifo_rst_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[267]),
		.qs(control_fifo_rst_qs)
	);
	prim_subreg #(
		.DW(12),
		.SWACCESS("RW"),
		.RESVAL(12'h0)
	) u_control_num(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(control_num_we),
		.wd(control_num_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[266-:12]),
		.qs(control_num_qs)
	);
	prim_subreg #(
		.DW(32),
		.SWACCESS("RW"),
		.RESVAL(32'h0)
	) u_addr(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(addr_we),
		.wd(addr_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[254-:32]),
		.qs(addr_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("W0C"),
		.RESVAL(1'h1)
	) u_region_cfg_regwen(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(region_cfg_regwen_we),
		.wd(region_cfg_regwen_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(),
		.qs(region_cfg_regwen_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_mp_region_cfg0_en0(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(mp_region_cfg0_en0_we & region_cfg_regwen_qs),
		.wd(mp_region_cfg0_en0_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[68]),
		.qs(mp_region_cfg0_en0_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_mp_region_cfg0_rd_en0(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(mp_region_cfg0_rd_en0_we & region_cfg_regwen_qs),
		.wd(mp_region_cfg0_rd_en0_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[67]),
		.qs(mp_region_cfg0_rd_en0_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_mp_region_cfg0_prog_en0(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(mp_region_cfg0_prog_en0_we & region_cfg_regwen_qs),
		.wd(mp_region_cfg0_prog_en0_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[66]),
		.qs(mp_region_cfg0_prog_en0_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_mp_region_cfg0_erase_en0(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(mp_region_cfg0_erase_en0_we & region_cfg_regwen_qs),
		.wd(mp_region_cfg0_erase_en0_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[65]),
		.qs(mp_region_cfg0_erase_en0_qs)
	);
	prim_subreg #(
		.DW(9),
		.SWACCESS("RW"),
		.RESVAL(9'h0)
	) u_mp_region_cfg0_base0(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(mp_region_cfg0_base0_we & region_cfg_regwen_qs),
		.wd(mp_region_cfg0_base0_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[64-:9]),
		.qs(mp_region_cfg0_base0_qs)
	);
	prim_subreg #(
		.DW(9),
		.SWACCESS("RW"),
		.RESVAL(9'h0)
	) u_mp_region_cfg0_size0(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(mp_region_cfg0_size0_we & region_cfg_regwen_qs),
		.wd(mp_region_cfg0_size0_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[55-:9]),
		.qs(mp_region_cfg0_size0_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_mp_region_cfg1_en1(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(mp_region_cfg1_en1_we & region_cfg_regwen_qs),
		.wd(mp_region_cfg1_en1_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[90]),
		.qs(mp_region_cfg1_en1_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_mp_region_cfg1_rd_en1(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(mp_region_cfg1_rd_en1_we & region_cfg_regwen_qs),
		.wd(mp_region_cfg1_rd_en1_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[89]),
		.qs(mp_region_cfg1_rd_en1_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_mp_region_cfg1_prog_en1(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(mp_region_cfg1_prog_en1_we & region_cfg_regwen_qs),
		.wd(mp_region_cfg1_prog_en1_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[88]),
		.qs(mp_region_cfg1_prog_en1_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_mp_region_cfg1_erase_en1(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(mp_region_cfg1_erase_en1_we & region_cfg_regwen_qs),
		.wd(mp_region_cfg1_erase_en1_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[87]),
		.qs(mp_region_cfg1_erase_en1_qs)
	);
	prim_subreg #(
		.DW(9),
		.SWACCESS("RW"),
		.RESVAL(9'h0)
	) u_mp_region_cfg1_base1(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(mp_region_cfg1_base1_we & region_cfg_regwen_qs),
		.wd(mp_region_cfg1_base1_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[86-:9]),
		.qs(mp_region_cfg1_base1_qs)
	);
	prim_subreg #(
		.DW(9),
		.SWACCESS("RW"),
		.RESVAL(9'h0)
	) u_mp_region_cfg1_size1(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(mp_region_cfg1_size1_we & region_cfg_regwen_qs),
		.wd(mp_region_cfg1_size1_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[77-:9]),
		.qs(mp_region_cfg1_size1_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_mp_region_cfg2_en2(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(mp_region_cfg2_en2_we & region_cfg_regwen_qs),
		.wd(mp_region_cfg2_en2_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[112]),
		.qs(mp_region_cfg2_en2_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_mp_region_cfg2_rd_en2(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(mp_region_cfg2_rd_en2_we & region_cfg_regwen_qs),
		.wd(mp_region_cfg2_rd_en2_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[111]),
		.qs(mp_region_cfg2_rd_en2_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_mp_region_cfg2_prog_en2(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(mp_region_cfg2_prog_en2_we & region_cfg_regwen_qs),
		.wd(mp_region_cfg2_prog_en2_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[110]),
		.qs(mp_region_cfg2_prog_en2_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_mp_region_cfg2_erase_en2(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(mp_region_cfg2_erase_en2_we & region_cfg_regwen_qs),
		.wd(mp_region_cfg2_erase_en2_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[109]),
		.qs(mp_region_cfg2_erase_en2_qs)
	);
	prim_subreg #(
		.DW(9),
		.SWACCESS("RW"),
		.RESVAL(9'h0)
	) u_mp_region_cfg2_base2(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(mp_region_cfg2_base2_we & region_cfg_regwen_qs),
		.wd(mp_region_cfg2_base2_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[108-:9]),
		.qs(mp_region_cfg2_base2_qs)
	);
	prim_subreg #(
		.DW(9),
		.SWACCESS("RW"),
		.RESVAL(9'h0)
	) u_mp_region_cfg2_size2(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(mp_region_cfg2_size2_we & region_cfg_regwen_qs),
		.wd(mp_region_cfg2_size2_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[99-:9]),
		.qs(mp_region_cfg2_size2_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_mp_region_cfg3_en3(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(mp_region_cfg3_en3_we & region_cfg_regwen_qs),
		.wd(mp_region_cfg3_en3_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[134]),
		.qs(mp_region_cfg3_en3_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_mp_region_cfg3_rd_en3(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(mp_region_cfg3_rd_en3_we & region_cfg_regwen_qs),
		.wd(mp_region_cfg3_rd_en3_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[133]),
		.qs(mp_region_cfg3_rd_en3_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_mp_region_cfg3_prog_en3(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(mp_region_cfg3_prog_en3_we & region_cfg_regwen_qs),
		.wd(mp_region_cfg3_prog_en3_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[132]),
		.qs(mp_region_cfg3_prog_en3_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_mp_region_cfg3_erase_en3(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(mp_region_cfg3_erase_en3_we & region_cfg_regwen_qs),
		.wd(mp_region_cfg3_erase_en3_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[131]),
		.qs(mp_region_cfg3_erase_en3_qs)
	);
	prim_subreg #(
		.DW(9),
		.SWACCESS("RW"),
		.RESVAL(9'h0)
	) u_mp_region_cfg3_base3(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(mp_region_cfg3_base3_we & region_cfg_regwen_qs),
		.wd(mp_region_cfg3_base3_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[130-:9]),
		.qs(mp_region_cfg3_base3_qs)
	);
	prim_subreg #(
		.DW(9),
		.SWACCESS("RW"),
		.RESVAL(9'h0)
	) u_mp_region_cfg3_size3(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(mp_region_cfg3_size3_we & region_cfg_regwen_qs),
		.wd(mp_region_cfg3_size3_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[121-:9]),
		.qs(mp_region_cfg3_size3_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_mp_region_cfg4_en4(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(mp_region_cfg4_en4_we & region_cfg_regwen_qs),
		.wd(mp_region_cfg4_en4_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[156]),
		.qs(mp_region_cfg4_en4_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_mp_region_cfg4_rd_en4(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(mp_region_cfg4_rd_en4_we & region_cfg_regwen_qs),
		.wd(mp_region_cfg4_rd_en4_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[155]),
		.qs(mp_region_cfg4_rd_en4_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_mp_region_cfg4_prog_en4(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(mp_region_cfg4_prog_en4_we & region_cfg_regwen_qs),
		.wd(mp_region_cfg4_prog_en4_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[154]),
		.qs(mp_region_cfg4_prog_en4_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_mp_region_cfg4_erase_en4(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(mp_region_cfg4_erase_en4_we & region_cfg_regwen_qs),
		.wd(mp_region_cfg4_erase_en4_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[153]),
		.qs(mp_region_cfg4_erase_en4_qs)
	);
	prim_subreg #(
		.DW(9),
		.SWACCESS("RW"),
		.RESVAL(9'h0)
	) u_mp_region_cfg4_base4(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(mp_region_cfg4_base4_we & region_cfg_regwen_qs),
		.wd(mp_region_cfg4_base4_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[152-:9]),
		.qs(mp_region_cfg4_base4_qs)
	);
	prim_subreg #(
		.DW(9),
		.SWACCESS("RW"),
		.RESVAL(9'h0)
	) u_mp_region_cfg4_size4(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(mp_region_cfg4_size4_we & region_cfg_regwen_qs),
		.wd(mp_region_cfg4_size4_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[143-:9]),
		.qs(mp_region_cfg4_size4_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_mp_region_cfg5_en5(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(mp_region_cfg5_en5_we & region_cfg_regwen_qs),
		.wd(mp_region_cfg5_en5_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[178]),
		.qs(mp_region_cfg5_en5_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_mp_region_cfg5_rd_en5(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(mp_region_cfg5_rd_en5_we & region_cfg_regwen_qs),
		.wd(mp_region_cfg5_rd_en5_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[177]),
		.qs(mp_region_cfg5_rd_en5_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_mp_region_cfg5_prog_en5(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(mp_region_cfg5_prog_en5_we & region_cfg_regwen_qs),
		.wd(mp_region_cfg5_prog_en5_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[176]),
		.qs(mp_region_cfg5_prog_en5_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_mp_region_cfg5_erase_en5(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(mp_region_cfg5_erase_en5_we & region_cfg_regwen_qs),
		.wd(mp_region_cfg5_erase_en5_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[175]),
		.qs(mp_region_cfg5_erase_en5_qs)
	);
	prim_subreg #(
		.DW(9),
		.SWACCESS("RW"),
		.RESVAL(9'h0)
	) u_mp_region_cfg5_base5(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(mp_region_cfg5_base5_we & region_cfg_regwen_qs),
		.wd(mp_region_cfg5_base5_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[174-:9]),
		.qs(mp_region_cfg5_base5_qs)
	);
	prim_subreg #(
		.DW(9),
		.SWACCESS("RW"),
		.RESVAL(9'h0)
	) u_mp_region_cfg5_size5(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(mp_region_cfg5_size5_we & region_cfg_regwen_qs),
		.wd(mp_region_cfg5_size5_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[165-:9]),
		.qs(mp_region_cfg5_size5_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_mp_region_cfg6_en6(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(mp_region_cfg6_en6_we & region_cfg_regwen_qs),
		.wd(mp_region_cfg6_en6_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[200]),
		.qs(mp_region_cfg6_en6_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_mp_region_cfg6_rd_en6(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(mp_region_cfg6_rd_en6_we & region_cfg_regwen_qs),
		.wd(mp_region_cfg6_rd_en6_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[199]),
		.qs(mp_region_cfg6_rd_en6_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_mp_region_cfg6_prog_en6(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(mp_region_cfg6_prog_en6_we & region_cfg_regwen_qs),
		.wd(mp_region_cfg6_prog_en6_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[198]),
		.qs(mp_region_cfg6_prog_en6_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_mp_region_cfg6_erase_en6(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(mp_region_cfg6_erase_en6_we & region_cfg_regwen_qs),
		.wd(mp_region_cfg6_erase_en6_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[197]),
		.qs(mp_region_cfg6_erase_en6_qs)
	);
	prim_subreg #(
		.DW(9),
		.SWACCESS("RW"),
		.RESVAL(9'h0)
	) u_mp_region_cfg6_base6(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(mp_region_cfg6_base6_we & region_cfg_regwen_qs),
		.wd(mp_region_cfg6_base6_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[196-:9]),
		.qs(mp_region_cfg6_base6_qs)
	);
	prim_subreg #(
		.DW(9),
		.SWACCESS("RW"),
		.RESVAL(9'h0)
	) u_mp_region_cfg6_size6(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(mp_region_cfg6_size6_we & region_cfg_regwen_qs),
		.wd(mp_region_cfg6_size6_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[187-:9]),
		.qs(mp_region_cfg6_size6_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_mp_region_cfg7_en7(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(mp_region_cfg7_en7_we & region_cfg_regwen_qs),
		.wd(mp_region_cfg7_en7_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[222]),
		.qs(mp_region_cfg7_en7_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_mp_region_cfg7_rd_en7(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(mp_region_cfg7_rd_en7_we & region_cfg_regwen_qs),
		.wd(mp_region_cfg7_rd_en7_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[221]),
		.qs(mp_region_cfg7_rd_en7_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_mp_region_cfg7_prog_en7(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(mp_region_cfg7_prog_en7_we & region_cfg_regwen_qs),
		.wd(mp_region_cfg7_prog_en7_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[220]),
		.qs(mp_region_cfg7_prog_en7_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_mp_region_cfg7_erase_en7(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(mp_region_cfg7_erase_en7_we & region_cfg_regwen_qs),
		.wd(mp_region_cfg7_erase_en7_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[219]),
		.qs(mp_region_cfg7_erase_en7_qs)
	);
	prim_subreg #(
		.DW(9),
		.SWACCESS("RW"),
		.RESVAL(9'h0)
	) u_mp_region_cfg7_base7(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(mp_region_cfg7_base7_we & region_cfg_regwen_qs),
		.wd(mp_region_cfg7_base7_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[218-:9]),
		.qs(mp_region_cfg7_base7_qs)
	);
	prim_subreg #(
		.DW(9),
		.SWACCESS("RW"),
		.RESVAL(9'h0)
	) u_mp_region_cfg7_size7(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(mp_region_cfg7_size7_we & region_cfg_regwen_qs),
		.wd(mp_region_cfg7_size7_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[209-:9]),
		.qs(mp_region_cfg7_size7_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_default_region_rd_en(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(default_region_rd_en_we),
		.wd(default_region_rd_en_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[46]),
		.qs(default_region_rd_en_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_default_region_prog_en(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(default_region_prog_en_we),
		.wd(default_region_prog_en_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[45]),
		.qs(default_region_prog_en_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_default_region_erase_en(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(default_region_erase_en_we),
		.wd(default_region_erase_en_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[44]),
		.qs(default_region_erase_en_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("W0C"),
		.RESVAL(1'h1)
	) u_bank_cfg_regwen(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(bank_cfg_regwen_we),
		.wd(bank_cfg_regwen_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(),
		.qs(bank_cfg_regwen_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_mp_bank_cfg_erase_en0(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(mp_bank_cfg_erase_en0_we & bank_cfg_regwen_qs),
		.wd(mp_bank_cfg_erase_en0_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[42]),
		.qs(mp_bank_cfg_erase_en0_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_mp_bank_cfg_erase_en1(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(mp_bank_cfg_erase_en1_we & bank_cfg_regwen_qs),
		.wd(mp_bank_cfg_erase_en1_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[43]),
		.qs(mp_bank_cfg_erase_en1_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_op_status_done(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(op_status_done_we),
		.wd(op_status_done_wd),
		.de(hw2reg[17]),
		.d(hw2reg[18]),
		.qe(),
		.q(),
		.qs(op_status_done_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_op_status_err(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(op_status_err_we),
		.wd(op_status_err_wd),
		.de(hw2reg[15]),
		.d(hw2reg[16]),
		.qe(),
		.q(),
		.qs(op_status_err_qs)
	);
	prim_subreg_ext #(.DW(1)) u_status_rd_full(
		.re(status_rd_full_re),
		.we(1'b0),
		.wd(1'sb0),
		.d(hw2reg[14]),
		.qre(),
		.qe(),
		.q(),
		.qs(status_rd_full_qs)
	);
	prim_subreg_ext #(.DW(1)) u_status_rd_empty(
		.re(status_rd_empty_re),
		.we(1'b0),
		.wd(1'sb0),
		.d(hw2reg[13]),
		.qre(),
		.qe(),
		.q(),
		.qs(status_rd_empty_qs)
	);
	prim_subreg_ext #(.DW(1)) u_status_prog_full(
		.re(status_prog_full_re),
		.we(1'b0),
		.wd(1'sb0),
		.d(hw2reg[12]),
		.qre(),
		.qe(),
		.q(),
		.qs(status_prog_full_qs)
	);
	prim_subreg_ext #(.DW(1)) u_status_prog_empty(
		.re(status_prog_empty_re),
		.we(1'b0),
		.wd(1'sb0),
		.d(hw2reg[11]),
		.qre(),
		.qe(),
		.q(),
		.qs(status_prog_empty_qs)
	);
	prim_subreg_ext #(.DW(1)) u_status_init_wip(
		.re(status_init_wip_re),
		.we(1'b0),
		.wd(1'sb0),
		.d(hw2reg[10]),
		.qre(),
		.qe(),
		.q(),
		.qs(status_init_wip_qs)
	);
	prim_subreg_ext #(.DW(9)) u_status_error_page(
		.re(status_error_page_re),
		.we(1'b0),
		.wd(1'sb0),
		.d(hw2reg[9-:9]),
		.qre(),
		.qe(),
		.q(),
		.qs(status_error_page_qs)
	);
	prim_subreg_ext #(.DW(1)) u_status_error_bank(
		.re(status_error_bank_re),
		.we(1'b0),
		.wd(1'sb0),
		.d(hw2reg[0]),
		.qre(),
		.qe(),
		.q(),
		.qs(status_error_bank_qs)
	);
	prim_subreg #(
		.DW(32),
		.SWACCESS("RW"),
		.RESVAL(32'h0)
	) u_scratch(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(scratch_we),
		.wd(scratch_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[41-:32]),
		.qs(scratch_qs)
	);
	prim_subreg #(
		.DW(5),
		.SWACCESS("RW"),
		.RESVAL(5'hf)
	) u_fifo_lvl_prog(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(fifo_lvl_prog_we),
		.wd(fifo_lvl_prog_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[9-:5]),
		.qs(fifo_lvl_prog_qs)
	);
	prim_subreg #(
		.DW(5),
		.SWACCESS("RW"),
		.RESVAL(5'hf)
	) u_fifo_lvl_rd(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(fifo_lvl_rd_we),
		.wd(fifo_lvl_rd_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[4-:5]),
		.qs(fifo_lvl_rd_qs)
	);
	reg [20:0] addr_hit;
	always @(*) begin
		addr_hit = 1'sb0;
		addr_hit[0] = reg_addr == FLASH_CTRL_INTR_STATE_OFFSET;
		addr_hit[1] = reg_addr == FLASH_CTRL_INTR_ENABLE_OFFSET;
		addr_hit[2] = reg_addr == FLASH_CTRL_INTR_TEST_OFFSET;
		addr_hit[3] = reg_addr == FLASH_CTRL_CONTROL_OFFSET;
		addr_hit[4] = reg_addr == FLASH_CTRL_ADDR_OFFSET;
		addr_hit[5] = reg_addr == FLASH_CTRL_REGION_CFG_REGWEN_OFFSET;
		addr_hit[6] = reg_addr == FLASH_CTRL_MP_REGION_CFG0_OFFSET;
		addr_hit[7] = reg_addr == FLASH_CTRL_MP_REGION_CFG1_OFFSET;
		addr_hit[8] = reg_addr == FLASH_CTRL_MP_REGION_CFG2_OFFSET;
		addr_hit[9] = reg_addr == FLASH_CTRL_MP_REGION_CFG3_OFFSET;
		addr_hit[10] = reg_addr == FLASH_CTRL_MP_REGION_CFG4_OFFSET;
		addr_hit[11] = reg_addr == FLASH_CTRL_MP_REGION_CFG5_OFFSET;
		addr_hit[12] = reg_addr == FLASH_CTRL_MP_REGION_CFG6_OFFSET;
		addr_hit[13] = reg_addr == FLASH_CTRL_MP_REGION_CFG7_OFFSET;
		addr_hit[14] = reg_addr == FLASH_CTRL_DEFAULT_REGION_OFFSET;
		addr_hit[15] = reg_addr == FLASH_CTRL_BANK_CFG_REGWEN_OFFSET;
		addr_hit[16] = reg_addr == FLASH_CTRL_MP_BANK_CFG_OFFSET;
		addr_hit[17] = reg_addr == FLASH_CTRL_OP_STATUS_OFFSET;
		addr_hit[18] = reg_addr == FLASH_CTRL_STATUS_OFFSET;
		addr_hit[19] = reg_addr == FLASH_CTRL_SCRATCH_OFFSET;
		addr_hit[20] = reg_addr == FLASH_CTRL_FIFO_LVL_OFFSET;
	end
	assign addrmiss = (reg_re || reg_we ? ~|addr_hit : 1'b0);
	always @(*) begin
		wr_err = 1'b0;
		if ((addr_hit[0] && reg_we) && (FLASH_CTRL_PERMIT[80+:4] != (FLASH_CTRL_PERMIT[80+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[1] && reg_we) && (FLASH_CTRL_PERMIT[76+:4] != (FLASH_CTRL_PERMIT[76+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[2] && reg_we) && (FLASH_CTRL_PERMIT[72+:4] != (FLASH_CTRL_PERMIT[72+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[3] && reg_we) && (FLASH_CTRL_PERMIT[68+:4] != (FLASH_CTRL_PERMIT[68+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[4] && reg_we) && (FLASH_CTRL_PERMIT[64+:4] != (FLASH_CTRL_PERMIT[64+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[5] && reg_we) && (FLASH_CTRL_PERMIT[60+:4] != (FLASH_CTRL_PERMIT[60+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[6] && reg_we) && (FLASH_CTRL_PERMIT[56+:4] != (FLASH_CTRL_PERMIT[56+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[7] && reg_we) && (FLASH_CTRL_PERMIT[52+:4] != (FLASH_CTRL_PERMIT[52+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[8] && reg_we) && (FLASH_CTRL_PERMIT[48+:4] != (FLASH_CTRL_PERMIT[48+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[9] && reg_we) && (FLASH_CTRL_PERMIT[44+:4] != (FLASH_CTRL_PERMIT[44+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[10] && reg_we) && (FLASH_CTRL_PERMIT[40+:4] != (FLASH_CTRL_PERMIT[40+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[11] && reg_we) && (FLASH_CTRL_PERMIT[36+:4] != (FLASH_CTRL_PERMIT[36+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[12] && reg_we) && (FLASH_CTRL_PERMIT[32+:4] != (FLASH_CTRL_PERMIT[32+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[13] && reg_we) && (FLASH_CTRL_PERMIT[28+:4] != (FLASH_CTRL_PERMIT[28+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[14] && reg_we) && (FLASH_CTRL_PERMIT[24+:4] != (FLASH_CTRL_PERMIT[24+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[15] && reg_we) && (FLASH_CTRL_PERMIT[20+:4] != (FLASH_CTRL_PERMIT[20+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[16] && reg_we) && (FLASH_CTRL_PERMIT[16+:4] != (FLASH_CTRL_PERMIT[16+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[17] && reg_we) && (FLASH_CTRL_PERMIT[12+:4] != (FLASH_CTRL_PERMIT[12+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[18] && reg_we) && (FLASH_CTRL_PERMIT[8+:4] != (FLASH_CTRL_PERMIT[8+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[19] && reg_we) && (FLASH_CTRL_PERMIT[4+:4] != (FLASH_CTRL_PERMIT[4+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[20] && reg_we) && (FLASH_CTRL_PERMIT[0+:4] != (FLASH_CTRL_PERMIT[0+:4] & reg_be)))
			wr_err = 1'b1;
	end
	assign intr_state_prog_empty_we = (addr_hit[0] & reg_we) & ~wr_err;
	assign intr_state_prog_empty_wd = reg_wdata[0];
	assign intr_state_prog_lvl_we = (addr_hit[0] & reg_we) & ~wr_err;
	assign intr_state_prog_lvl_wd = reg_wdata[1];
	assign intr_state_rd_full_we = (addr_hit[0] & reg_we) & ~wr_err;
	assign intr_state_rd_full_wd = reg_wdata[2];
	assign intr_state_rd_lvl_we = (addr_hit[0] & reg_we) & ~wr_err;
	assign intr_state_rd_lvl_wd = reg_wdata[3];
	assign intr_state_op_done_we = (addr_hit[0] & reg_we) & ~wr_err;
	assign intr_state_op_done_wd = reg_wdata[4];
	assign intr_state_op_error_we = (addr_hit[0] & reg_we) & ~wr_err;
	assign intr_state_op_error_wd = reg_wdata[5];
	assign intr_enable_prog_empty_we = (addr_hit[1] & reg_we) & ~wr_err;
	assign intr_enable_prog_empty_wd = reg_wdata[0];
	assign intr_enable_prog_lvl_we = (addr_hit[1] & reg_we) & ~wr_err;
	assign intr_enable_prog_lvl_wd = reg_wdata[1];
	assign intr_enable_rd_full_we = (addr_hit[1] & reg_we) & ~wr_err;
	assign intr_enable_rd_full_wd = reg_wdata[2];
	assign intr_enable_rd_lvl_we = (addr_hit[1] & reg_we) & ~wr_err;
	assign intr_enable_rd_lvl_wd = reg_wdata[3];
	assign intr_enable_op_done_we = (addr_hit[1] & reg_we) & ~wr_err;
	assign intr_enable_op_done_wd = reg_wdata[4];
	assign intr_enable_op_error_we = (addr_hit[1] & reg_we) & ~wr_err;
	assign intr_enable_op_error_wd = reg_wdata[5];
	assign intr_test_prog_empty_we = (addr_hit[2] & reg_we) & ~wr_err;
	assign intr_test_prog_empty_wd = reg_wdata[0];
	assign intr_test_prog_lvl_we = (addr_hit[2] & reg_we) & ~wr_err;
	assign intr_test_prog_lvl_wd = reg_wdata[1];
	assign intr_test_rd_full_we = (addr_hit[2] & reg_we) & ~wr_err;
	assign intr_test_rd_full_wd = reg_wdata[2];
	assign intr_test_rd_lvl_we = (addr_hit[2] & reg_we) & ~wr_err;
	assign intr_test_rd_lvl_wd = reg_wdata[3];
	assign intr_test_op_done_we = (addr_hit[2] & reg_we) & ~wr_err;
	assign intr_test_op_done_wd = reg_wdata[4];
	assign intr_test_op_error_we = (addr_hit[2] & reg_we) & ~wr_err;
	assign intr_test_op_error_wd = reg_wdata[5];
	assign control_start_we = (addr_hit[3] & reg_we) & ~wr_err;
	assign control_start_wd = reg_wdata[0];
	assign control_op_we = (addr_hit[3] & reg_we) & ~wr_err;
	assign control_op_wd = reg_wdata[5:4];
	assign control_erase_sel_we = (addr_hit[3] & reg_we) & ~wr_err;
	assign control_erase_sel_wd = reg_wdata[6];
	assign control_fifo_rst_we = (addr_hit[3] & reg_we) & ~wr_err;
	assign control_fifo_rst_wd = reg_wdata[7];
	assign control_num_we = (addr_hit[3] & reg_we) & ~wr_err;
	assign control_num_wd = reg_wdata[27:16];
	assign addr_we = (addr_hit[4] & reg_we) & ~wr_err;
	assign addr_wd = reg_wdata[31:0];
	assign region_cfg_regwen_we = (addr_hit[5] & reg_we) & ~wr_err;
	assign region_cfg_regwen_wd = reg_wdata[0];
	assign mp_region_cfg0_en0_we = (addr_hit[6] & reg_we) & ~wr_err;
	assign mp_region_cfg0_en0_wd = reg_wdata[0];
	assign mp_region_cfg0_rd_en0_we = (addr_hit[6] & reg_we) & ~wr_err;
	assign mp_region_cfg0_rd_en0_wd = reg_wdata[1];
	assign mp_region_cfg0_prog_en0_we = (addr_hit[6] & reg_we) & ~wr_err;
	assign mp_region_cfg0_prog_en0_wd = reg_wdata[2];
	assign mp_region_cfg0_erase_en0_we = (addr_hit[6] & reg_we) & ~wr_err;
	assign mp_region_cfg0_erase_en0_wd = reg_wdata[3];
	assign mp_region_cfg0_base0_we = (addr_hit[6] & reg_we) & ~wr_err;
	assign mp_region_cfg0_base0_wd = reg_wdata[12:4];
	assign mp_region_cfg0_size0_we = (addr_hit[6] & reg_we) & ~wr_err;
	assign mp_region_cfg0_size0_wd = reg_wdata[24:16];
	assign mp_region_cfg1_en1_we = (addr_hit[7] & reg_we) & ~wr_err;
	assign mp_region_cfg1_en1_wd = reg_wdata[0];
	assign mp_region_cfg1_rd_en1_we = (addr_hit[7] & reg_we) & ~wr_err;
	assign mp_region_cfg1_rd_en1_wd = reg_wdata[1];
	assign mp_region_cfg1_prog_en1_we = (addr_hit[7] & reg_we) & ~wr_err;
	assign mp_region_cfg1_prog_en1_wd = reg_wdata[2];
	assign mp_region_cfg1_erase_en1_we = (addr_hit[7] & reg_we) & ~wr_err;
	assign mp_region_cfg1_erase_en1_wd = reg_wdata[3];
	assign mp_region_cfg1_base1_we = (addr_hit[7] & reg_we) & ~wr_err;
	assign mp_region_cfg1_base1_wd = reg_wdata[12:4];
	assign mp_region_cfg1_size1_we = (addr_hit[7] & reg_we) & ~wr_err;
	assign mp_region_cfg1_size1_wd = reg_wdata[24:16];
	assign mp_region_cfg2_en2_we = (addr_hit[8] & reg_we) & ~wr_err;
	assign mp_region_cfg2_en2_wd = reg_wdata[0];
	assign mp_region_cfg2_rd_en2_we = (addr_hit[8] & reg_we) & ~wr_err;
	assign mp_region_cfg2_rd_en2_wd = reg_wdata[1];
	assign mp_region_cfg2_prog_en2_we = (addr_hit[8] & reg_we) & ~wr_err;
	assign mp_region_cfg2_prog_en2_wd = reg_wdata[2];
	assign mp_region_cfg2_erase_en2_we = (addr_hit[8] & reg_we) & ~wr_err;
	assign mp_region_cfg2_erase_en2_wd = reg_wdata[3];
	assign mp_region_cfg2_base2_we = (addr_hit[8] & reg_we) & ~wr_err;
	assign mp_region_cfg2_base2_wd = reg_wdata[12:4];
	assign mp_region_cfg2_size2_we = (addr_hit[8] & reg_we) & ~wr_err;
	assign mp_region_cfg2_size2_wd = reg_wdata[24:16];
	assign mp_region_cfg3_en3_we = (addr_hit[9] & reg_we) & ~wr_err;
	assign mp_region_cfg3_en3_wd = reg_wdata[0];
	assign mp_region_cfg3_rd_en3_we = (addr_hit[9] & reg_we) & ~wr_err;
	assign mp_region_cfg3_rd_en3_wd = reg_wdata[1];
	assign mp_region_cfg3_prog_en3_we = (addr_hit[9] & reg_we) & ~wr_err;
	assign mp_region_cfg3_prog_en3_wd = reg_wdata[2];
	assign mp_region_cfg3_erase_en3_we = (addr_hit[9] & reg_we) & ~wr_err;
	assign mp_region_cfg3_erase_en3_wd = reg_wdata[3];
	assign mp_region_cfg3_base3_we = (addr_hit[9] & reg_we) & ~wr_err;
	assign mp_region_cfg3_base3_wd = reg_wdata[12:4];
	assign mp_region_cfg3_size3_we = (addr_hit[9] & reg_we) & ~wr_err;
	assign mp_region_cfg3_size3_wd = reg_wdata[24:16];
	assign mp_region_cfg4_en4_we = (addr_hit[10] & reg_we) & ~wr_err;
	assign mp_region_cfg4_en4_wd = reg_wdata[0];
	assign mp_region_cfg4_rd_en4_we = (addr_hit[10] & reg_we) & ~wr_err;
	assign mp_region_cfg4_rd_en4_wd = reg_wdata[1];
	assign mp_region_cfg4_prog_en4_we = (addr_hit[10] & reg_we) & ~wr_err;
	assign mp_region_cfg4_prog_en4_wd = reg_wdata[2];
	assign mp_region_cfg4_erase_en4_we = (addr_hit[10] & reg_we) & ~wr_err;
	assign mp_region_cfg4_erase_en4_wd = reg_wdata[3];
	assign mp_region_cfg4_base4_we = (addr_hit[10] & reg_we) & ~wr_err;
	assign mp_region_cfg4_base4_wd = reg_wdata[12:4];
	assign mp_region_cfg4_size4_we = (addr_hit[10] & reg_we) & ~wr_err;
	assign mp_region_cfg4_size4_wd = reg_wdata[24:16];
	assign mp_region_cfg5_en5_we = (addr_hit[11] & reg_we) & ~wr_err;
	assign mp_region_cfg5_en5_wd = reg_wdata[0];
	assign mp_region_cfg5_rd_en5_we = (addr_hit[11] & reg_we) & ~wr_err;
	assign mp_region_cfg5_rd_en5_wd = reg_wdata[1];
	assign mp_region_cfg5_prog_en5_we = (addr_hit[11] & reg_we) & ~wr_err;
	assign mp_region_cfg5_prog_en5_wd = reg_wdata[2];
	assign mp_region_cfg5_erase_en5_we = (addr_hit[11] & reg_we) & ~wr_err;
	assign mp_region_cfg5_erase_en5_wd = reg_wdata[3];
	assign mp_region_cfg5_base5_we = (addr_hit[11] & reg_we) & ~wr_err;
	assign mp_region_cfg5_base5_wd = reg_wdata[12:4];
	assign mp_region_cfg5_size5_we = (addr_hit[11] & reg_we) & ~wr_err;
	assign mp_region_cfg5_size5_wd = reg_wdata[24:16];
	assign mp_region_cfg6_en6_we = (addr_hit[12] & reg_we) & ~wr_err;
	assign mp_region_cfg6_en6_wd = reg_wdata[0];
	assign mp_region_cfg6_rd_en6_we = (addr_hit[12] & reg_we) & ~wr_err;
	assign mp_region_cfg6_rd_en6_wd = reg_wdata[1];
	assign mp_region_cfg6_prog_en6_we = (addr_hit[12] & reg_we) & ~wr_err;
	assign mp_region_cfg6_prog_en6_wd = reg_wdata[2];
	assign mp_region_cfg6_erase_en6_we = (addr_hit[12] & reg_we) & ~wr_err;
	assign mp_region_cfg6_erase_en6_wd = reg_wdata[3];
	assign mp_region_cfg6_base6_we = (addr_hit[12] & reg_we) & ~wr_err;
	assign mp_region_cfg6_base6_wd = reg_wdata[12:4];
	assign mp_region_cfg6_size6_we = (addr_hit[12] & reg_we) & ~wr_err;
	assign mp_region_cfg6_size6_wd = reg_wdata[24:16];
	assign mp_region_cfg7_en7_we = (addr_hit[13] & reg_we) & ~wr_err;
	assign mp_region_cfg7_en7_wd = reg_wdata[0];
	assign mp_region_cfg7_rd_en7_we = (addr_hit[13] & reg_we) & ~wr_err;
	assign mp_region_cfg7_rd_en7_wd = reg_wdata[1];
	assign mp_region_cfg7_prog_en7_we = (addr_hit[13] & reg_we) & ~wr_err;
	assign mp_region_cfg7_prog_en7_wd = reg_wdata[2];
	assign mp_region_cfg7_erase_en7_we = (addr_hit[13] & reg_we) & ~wr_err;
	assign mp_region_cfg7_erase_en7_wd = reg_wdata[3];
	assign mp_region_cfg7_base7_we = (addr_hit[13] & reg_we) & ~wr_err;
	assign mp_region_cfg7_base7_wd = reg_wdata[12:4];
	assign mp_region_cfg7_size7_we = (addr_hit[13] & reg_we) & ~wr_err;
	assign mp_region_cfg7_size7_wd = reg_wdata[24:16];
	assign default_region_rd_en_we = (addr_hit[14] & reg_we) & ~wr_err;
	assign default_region_rd_en_wd = reg_wdata[0];
	assign default_region_prog_en_we = (addr_hit[14] & reg_we) & ~wr_err;
	assign default_region_prog_en_wd = reg_wdata[1];
	assign default_region_erase_en_we = (addr_hit[14] & reg_we) & ~wr_err;
	assign default_region_erase_en_wd = reg_wdata[2];
	assign bank_cfg_regwen_we = (addr_hit[15] & reg_we) & ~wr_err;
	assign bank_cfg_regwen_wd = reg_wdata[0];
	assign mp_bank_cfg_erase_en0_we = (addr_hit[16] & reg_we) & ~wr_err;
	assign mp_bank_cfg_erase_en0_wd = reg_wdata[0];
	assign mp_bank_cfg_erase_en1_we = (addr_hit[16] & reg_we) & ~wr_err;
	assign mp_bank_cfg_erase_en1_wd = reg_wdata[1];
	assign op_status_done_we = (addr_hit[17] & reg_we) & ~wr_err;
	assign op_status_done_wd = reg_wdata[0];
	assign op_status_err_we = (addr_hit[17] & reg_we) & ~wr_err;
	assign op_status_err_wd = reg_wdata[1];
	assign status_rd_full_re = addr_hit[18] && reg_re;
	assign status_rd_empty_re = addr_hit[18] && reg_re;
	assign status_prog_full_re = addr_hit[18] && reg_re;
	assign status_prog_empty_re = addr_hit[18] && reg_re;
	assign status_init_wip_re = addr_hit[18] && reg_re;
	assign status_error_page_re = addr_hit[18] && reg_re;
	assign status_error_bank_re = addr_hit[18] && reg_re;
	assign scratch_we = (addr_hit[19] & reg_we) & ~wr_err;
	assign scratch_wd = reg_wdata[31:0];
	assign fifo_lvl_prog_we = (addr_hit[20] & reg_we) & ~wr_err;
	assign fifo_lvl_prog_wd = reg_wdata[4:0];
	assign fifo_lvl_rd_we = (addr_hit[20] & reg_we) & ~wr_err;
	assign fifo_lvl_rd_wd = reg_wdata[12:8];
	always @(*) begin
		reg_rdata_next = 1'sb0;
		case (1'b1)
			addr_hit[0]: begin
				reg_rdata_next[0] = intr_state_prog_empty_qs;
				reg_rdata_next[1] = intr_state_prog_lvl_qs;
				reg_rdata_next[2] = intr_state_rd_full_qs;
				reg_rdata_next[3] = intr_state_rd_lvl_qs;
				reg_rdata_next[4] = intr_state_op_done_qs;
				reg_rdata_next[5] = intr_state_op_error_qs;
			end
			addr_hit[1]: begin
				reg_rdata_next[0] = intr_enable_prog_empty_qs;
				reg_rdata_next[1] = intr_enable_prog_lvl_qs;
				reg_rdata_next[2] = intr_enable_rd_full_qs;
				reg_rdata_next[3] = intr_enable_rd_lvl_qs;
				reg_rdata_next[4] = intr_enable_op_done_qs;
				reg_rdata_next[5] = intr_enable_op_error_qs;
			end
			addr_hit[2]: begin
				reg_rdata_next[0] = 1'sb0;
				reg_rdata_next[1] = 1'sb0;
				reg_rdata_next[2] = 1'sb0;
				reg_rdata_next[3] = 1'sb0;
				reg_rdata_next[4] = 1'sb0;
				reg_rdata_next[5] = 1'sb0;
			end
			addr_hit[3]: begin
				reg_rdata_next[0] = control_start_qs;
				reg_rdata_next[5:4] = control_op_qs;
				reg_rdata_next[6] = control_erase_sel_qs;
				reg_rdata_next[7] = control_fifo_rst_qs;
				reg_rdata_next[27:16] = control_num_qs;
			end
			addr_hit[4]: reg_rdata_next[31:0] = addr_qs;
			addr_hit[5]: reg_rdata_next[0] = region_cfg_regwen_qs;
			addr_hit[6]: begin
				reg_rdata_next[0] = mp_region_cfg0_en0_qs;
				reg_rdata_next[1] = mp_region_cfg0_rd_en0_qs;
				reg_rdata_next[2] = mp_region_cfg0_prog_en0_qs;
				reg_rdata_next[3] = mp_region_cfg0_erase_en0_qs;
				reg_rdata_next[12:4] = mp_region_cfg0_base0_qs;
				reg_rdata_next[24:16] = mp_region_cfg0_size0_qs;
			end
			addr_hit[7]: begin
				reg_rdata_next[0] = mp_region_cfg1_en1_qs;
				reg_rdata_next[1] = mp_region_cfg1_rd_en1_qs;
				reg_rdata_next[2] = mp_region_cfg1_prog_en1_qs;
				reg_rdata_next[3] = mp_region_cfg1_erase_en1_qs;
				reg_rdata_next[12:4] = mp_region_cfg1_base1_qs;
				reg_rdata_next[24:16] = mp_region_cfg1_size1_qs;
			end
			addr_hit[8]: begin
				reg_rdata_next[0] = mp_region_cfg2_en2_qs;
				reg_rdata_next[1] = mp_region_cfg2_rd_en2_qs;
				reg_rdata_next[2] = mp_region_cfg2_prog_en2_qs;
				reg_rdata_next[3] = mp_region_cfg2_erase_en2_qs;
				reg_rdata_next[12:4] = mp_region_cfg2_base2_qs;
				reg_rdata_next[24:16] = mp_region_cfg2_size2_qs;
			end
			addr_hit[9]: begin
				reg_rdata_next[0] = mp_region_cfg3_en3_qs;
				reg_rdata_next[1] = mp_region_cfg3_rd_en3_qs;
				reg_rdata_next[2] = mp_region_cfg3_prog_en3_qs;
				reg_rdata_next[3] = mp_region_cfg3_erase_en3_qs;
				reg_rdata_next[12:4] = mp_region_cfg3_base3_qs;
				reg_rdata_next[24:16] = mp_region_cfg3_size3_qs;
			end
			addr_hit[10]: begin
				reg_rdata_next[0] = mp_region_cfg4_en4_qs;
				reg_rdata_next[1] = mp_region_cfg4_rd_en4_qs;
				reg_rdata_next[2] = mp_region_cfg4_prog_en4_qs;
				reg_rdata_next[3] = mp_region_cfg4_erase_en4_qs;
				reg_rdata_next[12:4] = mp_region_cfg4_base4_qs;
				reg_rdata_next[24:16] = mp_region_cfg4_size4_qs;
			end
			addr_hit[11]: begin
				reg_rdata_next[0] = mp_region_cfg5_en5_qs;
				reg_rdata_next[1] = mp_region_cfg5_rd_en5_qs;
				reg_rdata_next[2] = mp_region_cfg5_prog_en5_qs;
				reg_rdata_next[3] = mp_region_cfg5_erase_en5_qs;
				reg_rdata_next[12:4] = mp_region_cfg5_base5_qs;
				reg_rdata_next[24:16] = mp_region_cfg5_size5_qs;
			end
			addr_hit[12]: begin
				reg_rdata_next[0] = mp_region_cfg6_en6_qs;
				reg_rdata_next[1] = mp_region_cfg6_rd_en6_qs;
				reg_rdata_next[2] = mp_region_cfg6_prog_en6_qs;
				reg_rdata_next[3] = mp_region_cfg6_erase_en6_qs;
				reg_rdata_next[12:4] = mp_region_cfg6_base6_qs;
				reg_rdata_next[24:16] = mp_region_cfg6_size6_qs;
			end
			addr_hit[13]: begin
				reg_rdata_next[0] = mp_region_cfg7_en7_qs;
				reg_rdata_next[1] = mp_region_cfg7_rd_en7_qs;
				reg_rdata_next[2] = mp_region_cfg7_prog_en7_qs;
				reg_rdata_next[3] = mp_region_cfg7_erase_en7_qs;
				reg_rdata_next[12:4] = mp_region_cfg7_base7_qs;
				reg_rdata_next[24:16] = mp_region_cfg7_size7_qs;
			end
			addr_hit[14]: begin
				reg_rdata_next[0] = default_region_rd_en_qs;
				reg_rdata_next[1] = default_region_prog_en_qs;
				reg_rdata_next[2] = default_region_erase_en_qs;
			end
			addr_hit[15]: reg_rdata_next[0] = bank_cfg_regwen_qs;
			addr_hit[16]: begin
				reg_rdata_next[0] = mp_bank_cfg_erase_en0_qs;
				reg_rdata_next[1] = mp_bank_cfg_erase_en1_qs;
			end
			addr_hit[17]: begin
				reg_rdata_next[0] = op_status_done_qs;
				reg_rdata_next[1] = op_status_err_qs;
			end
			addr_hit[18]: begin
				reg_rdata_next[0] = status_rd_full_qs;
				reg_rdata_next[1] = status_rd_empty_qs;
				reg_rdata_next[2] = status_prog_full_qs;
				reg_rdata_next[3] = status_prog_empty_qs;
				reg_rdata_next[4] = status_init_wip_qs;
				reg_rdata_next[16:8] = status_error_page_qs;
				reg_rdata_next[17] = status_error_bank_qs;
			end
			addr_hit[19]: reg_rdata_next[31:0] = scratch_qs;
			addr_hit[20]: begin
				reg_rdata_next[4:0] = fifo_lvl_prog_qs;
				reg_rdata_next[12:8] = fifo_lvl_rd_qs;
			end
			default: reg_rdata_next = 1'sb1;
		endcase
	end
endmodule
