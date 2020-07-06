module usbdev_reg_top (
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
	output wire [343:0] reg2hw;
	input wire [176:0] hw2reg;
	input devmode_i;
	parameter signed [31:0] NEndpoints = 12;
	parameter [11:0] USBDEV_INTR_STATE_OFFSET = 12'h 0;
	parameter [11:0] USBDEV_INTR_ENABLE_OFFSET = 12'h 4;
	parameter [11:0] USBDEV_INTR_TEST_OFFSET = 12'h 8;
	parameter [11:0] USBDEV_USBCTRL_OFFSET = 12'h c;
	parameter [11:0] USBDEV_USBSTAT_OFFSET = 12'h 10;
	parameter [11:0] USBDEV_AVBUFFER_OFFSET = 12'h 14;
	parameter [11:0] USBDEV_RXFIFO_OFFSET = 12'h 18;
	parameter [11:0] USBDEV_RXENABLE_SETUP_OFFSET = 12'h 1c;
	parameter [11:0] USBDEV_RXENABLE_OUT_OFFSET = 12'h 20;
	parameter [11:0] USBDEV_IN_SENT_OFFSET = 12'h 24;
	parameter [11:0] USBDEV_STALL_OFFSET = 12'h 28;
	parameter [11:0] USBDEV_CONFIGIN0_OFFSET = 12'h 2c;
	parameter [11:0] USBDEV_CONFIGIN1_OFFSET = 12'h 30;
	parameter [11:0] USBDEV_CONFIGIN2_OFFSET = 12'h 34;
	parameter [11:0] USBDEV_CONFIGIN3_OFFSET = 12'h 38;
	parameter [11:0] USBDEV_CONFIGIN4_OFFSET = 12'h 3c;
	parameter [11:0] USBDEV_CONFIGIN5_OFFSET = 12'h 40;
	parameter [11:0] USBDEV_CONFIGIN6_OFFSET = 12'h 44;
	parameter [11:0] USBDEV_CONFIGIN7_OFFSET = 12'h 48;
	parameter [11:0] USBDEV_CONFIGIN8_OFFSET = 12'h 4c;
	parameter [11:0] USBDEV_CONFIGIN9_OFFSET = 12'h 50;
	parameter [11:0] USBDEV_CONFIGIN10_OFFSET = 12'h 54;
	parameter [11:0] USBDEV_CONFIGIN11_OFFSET = 12'h 58;
	parameter [11:0] USBDEV_ISO_OFFSET = 12'h 5c;
	parameter [11:0] USBDEV_DATA_TOGGLE_CLEAR_OFFSET = 12'h 60;
	parameter [11:0] USBDEV_PHY_CONFIG_OFFSET = 12'h 64;
	parameter [11:0] USBDEV_BUFFER_OFFSET = 12'h 800;
	parameter [11:0] USBDEV_BUFFER_SIZE = 12'h 800;
	parameter [103:0] USBDEV_PERMIT = {4'b 0011, 4'b 0011, 4'b 0011, 4'b 0111, 4'b 1111, 4'b 0001, 4'b 0111, 4'b 0011, 4'b 0011, 4'b 0011, 4'b 0011, 4'b 1111, 4'b 1111, 4'b 1111, 4'b 1111, 4'b 1111, 4'b 1111, 4'b 1111, 4'b 1111, 4'b 1111, 4'b 1111, 4'b 1111, 4'b 1111, 4'b 0011, 4'b 0011, 4'b 0001};
	localparam USBDEV_INTR_STATE = 0;
	localparam USBDEV_INTR_ENABLE = 1;
	localparam USBDEV_STALL = 10;
	localparam USBDEV_CONFIGIN0 = 11;
	localparam USBDEV_CONFIGIN1 = 12;
	localparam USBDEV_CONFIGIN2 = 13;
	localparam USBDEV_CONFIGIN3 = 14;
	localparam USBDEV_CONFIGIN4 = 15;
	localparam USBDEV_CONFIGIN5 = 16;
	localparam USBDEV_CONFIGIN6 = 17;
	localparam USBDEV_CONFIGIN7 = 18;
	localparam USBDEV_CONFIGIN8 = 19;
	localparam USBDEV_INTR_TEST = 2;
	localparam USBDEV_CONFIGIN9 = 20;
	localparam USBDEV_CONFIGIN10 = 21;
	localparam USBDEV_CONFIGIN11 = 22;
	localparam USBDEV_ISO = 23;
	localparam USBDEV_DATA_TOGGLE_CLEAR = 24;
	localparam USBDEV_PHY_CONFIG = 25;
	localparam USBDEV_USBCTRL = 3;
	localparam USBDEV_USBSTAT = 4;
	localparam USBDEV_AVBUFFER = 5;
	localparam USBDEV_RXFIFO = 6;
	localparam USBDEV_RXENABLE_SETUP = 7;
	localparam USBDEV_RXENABLE_OUT = 8;
	localparam USBDEV_IN_SENT = 9;
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
	wire intr_state_pkt_received_qs;
	wire intr_state_pkt_received_wd;
	wire intr_state_pkt_received_we;
	wire intr_state_pkt_sent_qs;
	wire intr_state_pkt_sent_wd;
	wire intr_state_pkt_sent_we;
	wire intr_state_disconnected_qs;
	wire intr_state_disconnected_wd;
	wire intr_state_disconnected_we;
	wire intr_state_host_lost_qs;
	wire intr_state_host_lost_wd;
	wire intr_state_host_lost_we;
	wire intr_state_link_reset_qs;
	wire intr_state_link_reset_wd;
	wire intr_state_link_reset_we;
	wire intr_state_link_suspend_qs;
	wire intr_state_link_suspend_wd;
	wire intr_state_link_suspend_we;
	wire intr_state_link_resume_qs;
	wire intr_state_link_resume_wd;
	wire intr_state_link_resume_we;
	wire intr_state_av_empty_qs;
	wire intr_state_av_empty_wd;
	wire intr_state_av_empty_we;
	wire intr_state_rx_full_qs;
	wire intr_state_rx_full_wd;
	wire intr_state_rx_full_we;
	wire intr_state_av_overflow_qs;
	wire intr_state_av_overflow_wd;
	wire intr_state_av_overflow_we;
	wire intr_state_link_in_err_qs;
	wire intr_state_link_in_err_wd;
	wire intr_state_link_in_err_we;
	wire intr_state_rx_crc_err_qs;
	wire intr_state_rx_crc_err_wd;
	wire intr_state_rx_crc_err_we;
	wire intr_state_rx_pid_err_qs;
	wire intr_state_rx_pid_err_wd;
	wire intr_state_rx_pid_err_we;
	wire intr_state_rx_bitstuff_err_qs;
	wire intr_state_rx_bitstuff_err_wd;
	wire intr_state_rx_bitstuff_err_we;
	wire intr_state_frame_qs;
	wire intr_state_frame_wd;
	wire intr_state_frame_we;
	wire intr_state_connected_qs;
	wire intr_state_connected_wd;
	wire intr_state_connected_we;
	wire intr_enable_pkt_received_qs;
	wire intr_enable_pkt_received_wd;
	wire intr_enable_pkt_received_we;
	wire intr_enable_pkt_sent_qs;
	wire intr_enable_pkt_sent_wd;
	wire intr_enable_pkt_sent_we;
	wire intr_enable_disconnected_qs;
	wire intr_enable_disconnected_wd;
	wire intr_enable_disconnected_we;
	wire intr_enable_host_lost_qs;
	wire intr_enable_host_lost_wd;
	wire intr_enable_host_lost_we;
	wire intr_enable_link_reset_qs;
	wire intr_enable_link_reset_wd;
	wire intr_enable_link_reset_we;
	wire intr_enable_link_suspend_qs;
	wire intr_enable_link_suspend_wd;
	wire intr_enable_link_suspend_we;
	wire intr_enable_link_resume_qs;
	wire intr_enable_link_resume_wd;
	wire intr_enable_link_resume_we;
	wire intr_enable_av_empty_qs;
	wire intr_enable_av_empty_wd;
	wire intr_enable_av_empty_we;
	wire intr_enable_rx_full_qs;
	wire intr_enable_rx_full_wd;
	wire intr_enable_rx_full_we;
	wire intr_enable_av_overflow_qs;
	wire intr_enable_av_overflow_wd;
	wire intr_enable_av_overflow_we;
	wire intr_enable_link_in_err_qs;
	wire intr_enable_link_in_err_wd;
	wire intr_enable_link_in_err_we;
	wire intr_enable_rx_crc_err_qs;
	wire intr_enable_rx_crc_err_wd;
	wire intr_enable_rx_crc_err_we;
	wire intr_enable_rx_pid_err_qs;
	wire intr_enable_rx_pid_err_wd;
	wire intr_enable_rx_pid_err_we;
	wire intr_enable_rx_bitstuff_err_qs;
	wire intr_enable_rx_bitstuff_err_wd;
	wire intr_enable_rx_bitstuff_err_we;
	wire intr_enable_frame_qs;
	wire intr_enable_frame_wd;
	wire intr_enable_frame_we;
	wire intr_enable_connected_qs;
	wire intr_enable_connected_wd;
	wire intr_enable_connected_we;
	wire intr_test_pkt_received_wd;
	wire intr_test_pkt_received_we;
	wire intr_test_pkt_sent_wd;
	wire intr_test_pkt_sent_we;
	wire intr_test_disconnected_wd;
	wire intr_test_disconnected_we;
	wire intr_test_host_lost_wd;
	wire intr_test_host_lost_we;
	wire intr_test_link_reset_wd;
	wire intr_test_link_reset_we;
	wire intr_test_link_suspend_wd;
	wire intr_test_link_suspend_we;
	wire intr_test_link_resume_wd;
	wire intr_test_link_resume_we;
	wire intr_test_av_empty_wd;
	wire intr_test_av_empty_we;
	wire intr_test_rx_full_wd;
	wire intr_test_rx_full_we;
	wire intr_test_av_overflow_wd;
	wire intr_test_av_overflow_we;
	wire intr_test_link_in_err_wd;
	wire intr_test_link_in_err_we;
	wire intr_test_rx_crc_err_wd;
	wire intr_test_rx_crc_err_we;
	wire intr_test_rx_pid_err_wd;
	wire intr_test_rx_pid_err_we;
	wire intr_test_rx_bitstuff_err_wd;
	wire intr_test_rx_bitstuff_err_we;
	wire intr_test_frame_wd;
	wire intr_test_frame_we;
	wire intr_test_connected_wd;
	wire intr_test_connected_we;
	wire usbctrl_enable_qs;
	wire usbctrl_enable_wd;
	wire usbctrl_enable_we;
	wire [6:0] usbctrl_device_address_qs;
	wire [6:0] usbctrl_device_address_wd;
	wire usbctrl_device_address_we;
	wire [10:0] usbstat_frame_qs;
	wire usbstat_frame_re;
	wire usbstat_host_lost_qs;
	wire usbstat_host_lost_re;
	wire [2:0] usbstat_link_state_qs;
	wire usbstat_link_state_re;
	wire usbstat_usb_sense_qs;
	wire usbstat_usb_sense_re;
	wire [2:0] usbstat_av_depth_qs;
	wire usbstat_av_depth_re;
	wire usbstat_av_full_qs;
	wire usbstat_av_full_re;
	wire [2:0] usbstat_rx_depth_qs;
	wire usbstat_rx_depth_re;
	wire usbstat_rx_empty_qs;
	wire usbstat_rx_empty_re;
	wire [4:0] avbuffer_wd;
	wire avbuffer_we;
	wire [4:0] rxfifo_buffer_qs;
	wire rxfifo_buffer_re;
	wire [6:0] rxfifo_size_qs;
	wire rxfifo_size_re;
	wire rxfifo_setup_qs;
	wire rxfifo_setup_re;
	wire [3:0] rxfifo_ep_qs;
	wire rxfifo_ep_re;
	wire rxenable_setup_setup0_qs;
	wire rxenable_setup_setup0_wd;
	wire rxenable_setup_setup0_we;
	wire rxenable_setup_setup1_qs;
	wire rxenable_setup_setup1_wd;
	wire rxenable_setup_setup1_we;
	wire rxenable_setup_setup2_qs;
	wire rxenable_setup_setup2_wd;
	wire rxenable_setup_setup2_we;
	wire rxenable_setup_setup3_qs;
	wire rxenable_setup_setup3_wd;
	wire rxenable_setup_setup3_we;
	wire rxenable_setup_setup4_qs;
	wire rxenable_setup_setup4_wd;
	wire rxenable_setup_setup4_we;
	wire rxenable_setup_setup5_qs;
	wire rxenable_setup_setup5_wd;
	wire rxenable_setup_setup5_we;
	wire rxenable_setup_setup6_qs;
	wire rxenable_setup_setup6_wd;
	wire rxenable_setup_setup6_we;
	wire rxenable_setup_setup7_qs;
	wire rxenable_setup_setup7_wd;
	wire rxenable_setup_setup7_we;
	wire rxenable_setup_setup8_qs;
	wire rxenable_setup_setup8_wd;
	wire rxenable_setup_setup8_we;
	wire rxenable_setup_setup9_qs;
	wire rxenable_setup_setup9_wd;
	wire rxenable_setup_setup9_we;
	wire rxenable_setup_setup10_qs;
	wire rxenable_setup_setup10_wd;
	wire rxenable_setup_setup10_we;
	wire rxenable_setup_setup11_qs;
	wire rxenable_setup_setup11_wd;
	wire rxenable_setup_setup11_we;
	wire rxenable_out_out0_qs;
	wire rxenable_out_out0_wd;
	wire rxenable_out_out0_we;
	wire rxenable_out_out1_qs;
	wire rxenable_out_out1_wd;
	wire rxenable_out_out1_we;
	wire rxenable_out_out2_qs;
	wire rxenable_out_out2_wd;
	wire rxenable_out_out2_we;
	wire rxenable_out_out3_qs;
	wire rxenable_out_out3_wd;
	wire rxenable_out_out3_we;
	wire rxenable_out_out4_qs;
	wire rxenable_out_out4_wd;
	wire rxenable_out_out4_we;
	wire rxenable_out_out5_qs;
	wire rxenable_out_out5_wd;
	wire rxenable_out_out5_we;
	wire rxenable_out_out6_qs;
	wire rxenable_out_out6_wd;
	wire rxenable_out_out6_we;
	wire rxenable_out_out7_qs;
	wire rxenable_out_out7_wd;
	wire rxenable_out_out7_we;
	wire rxenable_out_out8_qs;
	wire rxenable_out_out8_wd;
	wire rxenable_out_out8_we;
	wire rxenable_out_out9_qs;
	wire rxenable_out_out9_wd;
	wire rxenable_out_out9_we;
	wire rxenable_out_out10_qs;
	wire rxenable_out_out10_wd;
	wire rxenable_out_out10_we;
	wire rxenable_out_out11_qs;
	wire rxenable_out_out11_wd;
	wire rxenable_out_out11_we;
	wire in_sent_sent0_qs;
	wire in_sent_sent0_wd;
	wire in_sent_sent0_we;
	wire in_sent_sent1_qs;
	wire in_sent_sent1_wd;
	wire in_sent_sent1_we;
	wire in_sent_sent2_qs;
	wire in_sent_sent2_wd;
	wire in_sent_sent2_we;
	wire in_sent_sent3_qs;
	wire in_sent_sent3_wd;
	wire in_sent_sent3_we;
	wire in_sent_sent4_qs;
	wire in_sent_sent4_wd;
	wire in_sent_sent4_we;
	wire in_sent_sent5_qs;
	wire in_sent_sent5_wd;
	wire in_sent_sent5_we;
	wire in_sent_sent6_qs;
	wire in_sent_sent6_wd;
	wire in_sent_sent6_we;
	wire in_sent_sent7_qs;
	wire in_sent_sent7_wd;
	wire in_sent_sent7_we;
	wire in_sent_sent8_qs;
	wire in_sent_sent8_wd;
	wire in_sent_sent8_we;
	wire in_sent_sent9_qs;
	wire in_sent_sent9_wd;
	wire in_sent_sent9_we;
	wire in_sent_sent10_qs;
	wire in_sent_sent10_wd;
	wire in_sent_sent10_we;
	wire in_sent_sent11_qs;
	wire in_sent_sent11_wd;
	wire in_sent_sent11_we;
	wire stall_stall0_qs;
	wire stall_stall0_wd;
	wire stall_stall0_we;
	wire stall_stall1_qs;
	wire stall_stall1_wd;
	wire stall_stall1_we;
	wire stall_stall2_qs;
	wire stall_stall2_wd;
	wire stall_stall2_we;
	wire stall_stall3_qs;
	wire stall_stall3_wd;
	wire stall_stall3_we;
	wire stall_stall4_qs;
	wire stall_stall4_wd;
	wire stall_stall4_we;
	wire stall_stall5_qs;
	wire stall_stall5_wd;
	wire stall_stall5_we;
	wire stall_stall6_qs;
	wire stall_stall6_wd;
	wire stall_stall6_we;
	wire stall_stall7_qs;
	wire stall_stall7_wd;
	wire stall_stall7_we;
	wire stall_stall8_qs;
	wire stall_stall8_wd;
	wire stall_stall8_we;
	wire stall_stall9_qs;
	wire stall_stall9_wd;
	wire stall_stall9_we;
	wire stall_stall10_qs;
	wire stall_stall10_wd;
	wire stall_stall10_we;
	wire stall_stall11_qs;
	wire stall_stall11_wd;
	wire stall_stall11_we;
	wire [4:0] configin0_buffer0_qs;
	wire [4:0] configin0_buffer0_wd;
	wire configin0_buffer0_we;
	wire [6:0] configin0_size0_qs;
	wire [6:0] configin0_size0_wd;
	wire configin0_size0_we;
	wire configin0_pend0_qs;
	wire configin0_pend0_wd;
	wire configin0_pend0_we;
	wire configin0_rdy0_qs;
	wire configin0_rdy0_wd;
	wire configin0_rdy0_we;
	wire [4:0] configin1_buffer1_qs;
	wire [4:0] configin1_buffer1_wd;
	wire configin1_buffer1_we;
	wire [6:0] configin1_size1_qs;
	wire [6:0] configin1_size1_wd;
	wire configin1_size1_we;
	wire configin1_pend1_qs;
	wire configin1_pend1_wd;
	wire configin1_pend1_we;
	wire configin1_rdy1_qs;
	wire configin1_rdy1_wd;
	wire configin1_rdy1_we;
	wire [4:0] configin2_buffer2_qs;
	wire [4:0] configin2_buffer2_wd;
	wire configin2_buffer2_we;
	wire [6:0] configin2_size2_qs;
	wire [6:0] configin2_size2_wd;
	wire configin2_size2_we;
	wire configin2_pend2_qs;
	wire configin2_pend2_wd;
	wire configin2_pend2_we;
	wire configin2_rdy2_qs;
	wire configin2_rdy2_wd;
	wire configin2_rdy2_we;
	wire [4:0] configin3_buffer3_qs;
	wire [4:0] configin3_buffer3_wd;
	wire configin3_buffer3_we;
	wire [6:0] configin3_size3_qs;
	wire [6:0] configin3_size3_wd;
	wire configin3_size3_we;
	wire configin3_pend3_qs;
	wire configin3_pend3_wd;
	wire configin3_pend3_we;
	wire configin3_rdy3_qs;
	wire configin3_rdy3_wd;
	wire configin3_rdy3_we;
	wire [4:0] configin4_buffer4_qs;
	wire [4:0] configin4_buffer4_wd;
	wire configin4_buffer4_we;
	wire [6:0] configin4_size4_qs;
	wire [6:0] configin4_size4_wd;
	wire configin4_size4_we;
	wire configin4_pend4_qs;
	wire configin4_pend4_wd;
	wire configin4_pend4_we;
	wire configin4_rdy4_qs;
	wire configin4_rdy4_wd;
	wire configin4_rdy4_we;
	wire [4:0] configin5_buffer5_qs;
	wire [4:0] configin5_buffer5_wd;
	wire configin5_buffer5_we;
	wire [6:0] configin5_size5_qs;
	wire [6:0] configin5_size5_wd;
	wire configin5_size5_we;
	wire configin5_pend5_qs;
	wire configin5_pend5_wd;
	wire configin5_pend5_we;
	wire configin5_rdy5_qs;
	wire configin5_rdy5_wd;
	wire configin5_rdy5_we;
	wire [4:0] configin6_buffer6_qs;
	wire [4:0] configin6_buffer6_wd;
	wire configin6_buffer6_we;
	wire [6:0] configin6_size6_qs;
	wire [6:0] configin6_size6_wd;
	wire configin6_size6_we;
	wire configin6_pend6_qs;
	wire configin6_pend6_wd;
	wire configin6_pend6_we;
	wire configin6_rdy6_qs;
	wire configin6_rdy6_wd;
	wire configin6_rdy6_we;
	wire [4:0] configin7_buffer7_qs;
	wire [4:0] configin7_buffer7_wd;
	wire configin7_buffer7_we;
	wire [6:0] configin7_size7_qs;
	wire [6:0] configin7_size7_wd;
	wire configin7_size7_we;
	wire configin7_pend7_qs;
	wire configin7_pend7_wd;
	wire configin7_pend7_we;
	wire configin7_rdy7_qs;
	wire configin7_rdy7_wd;
	wire configin7_rdy7_we;
	wire [4:0] configin8_buffer8_qs;
	wire [4:0] configin8_buffer8_wd;
	wire configin8_buffer8_we;
	wire [6:0] configin8_size8_qs;
	wire [6:0] configin8_size8_wd;
	wire configin8_size8_we;
	wire configin8_pend8_qs;
	wire configin8_pend8_wd;
	wire configin8_pend8_we;
	wire configin8_rdy8_qs;
	wire configin8_rdy8_wd;
	wire configin8_rdy8_we;
	wire [4:0] configin9_buffer9_qs;
	wire [4:0] configin9_buffer9_wd;
	wire configin9_buffer9_we;
	wire [6:0] configin9_size9_qs;
	wire [6:0] configin9_size9_wd;
	wire configin9_size9_we;
	wire configin9_pend9_qs;
	wire configin9_pend9_wd;
	wire configin9_pend9_we;
	wire configin9_rdy9_qs;
	wire configin9_rdy9_wd;
	wire configin9_rdy9_we;
	wire [4:0] configin10_buffer10_qs;
	wire [4:0] configin10_buffer10_wd;
	wire configin10_buffer10_we;
	wire [6:0] configin10_size10_qs;
	wire [6:0] configin10_size10_wd;
	wire configin10_size10_we;
	wire configin10_pend10_qs;
	wire configin10_pend10_wd;
	wire configin10_pend10_we;
	wire configin10_rdy10_qs;
	wire configin10_rdy10_wd;
	wire configin10_rdy10_we;
	wire [4:0] configin11_buffer11_qs;
	wire [4:0] configin11_buffer11_wd;
	wire configin11_buffer11_we;
	wire [6:0] configin11_size11_qs;
	wire [6:0] configin11_size11_wd;
	wire configin11_size11_we;
	wire configin11_pend11_qs;
	wire configin11_pend11_wd;
	wire configin11_pend11_we;
	wire configin11_rdy11_qs;
	wire configin11_rdy11_wd;
	wire configin11_rdy11_we;
	wire iso_iso0_qs;
	wire iso_iso0_wd;
	wire iso_iso0_we;
	wire iso_iso1_qs;
	wire iso_iso1_wd;
	wire iso_iso1_we;
	wire iso_iso2_qs;
	wire iso_iso2_wd;
	wire iso_iso2_we;
	wire iso_iso3_qs;
	wire iso_iso3_wd;
	wire iso_iso3_we;
	wire iso_iso4_qs;
	wire iso_iso4_wd;
	wire iso_iso4_we;
	wire iso_iso5_qs;
	wire iso_iso5_wd;
	wire iso_iso5_we;
	wire iso_iso6_qs;
	wire iso_iso6_wd;
	wire iso_iso6_we;
	wire iso_iso7_qs;
	wire iso_iso7_wd;
	wire iso_iso7_we;
	wire iso_iso8_qs;
	wire iso_iso8_wd;
	wire iso_iso8_we;
	wire iso_iso9_qs;
	wire iso_iso9_wd;
	wire iso_iso9_we;
	wire iso_iso10_qs;
	wire iso_iso10_wd;
	wire iso_iso10_we;
	wire iso_iso11_qs;
	wire iso_iso11_wd;
	wire iso_iso11_we;
	wire data_toggle_clear_clear0_wd;
	wire data_toggle_clear_clear0_we;
	wire data_toggle_clear_clear1_wd;
	wire data_toggle_clear_clear1_we;
	wire data_toggle_clear_clear2_wd;
	wire data_toggle_clear_clear2_we;
	wire data_toggle_clear_clear3_wd;
	wire data_toggle_clear_clear3_we;
	wire data_toggle_clear_clear4_wd;
	wire data_toggle_clear_clear4_we;
	wire data_toggle_clear_clear5_wd;
	wire data_toggle_clear_clear5_we;
	wire data_toggle_clear_clear6_wd;
	wire data_toggle_clear_clear6_we;
	wire data_toggle_clear_clear7_wd;
	wire data_toggle_clear_clear7_we;
	wire data_toggle_clear_clear8_wd;
	wire data_toggle_clear_clear8_we;
	wire data_toggle_clear_clear9_wd;
	wire data_toggle_clear_clear9_we;
	wire data_toggle_clear_clear10_wd;
	wire data_toggle_clear_clear10_we;
	wire data_toggle_clear_clear11_wd;
	wire data_toggle_clear_clear11_we;
	wire phy_config_rx_differential_mode_qs;
	wire phy_config_rx_differential_mode_wd;
	wire phy_config_rx_differential_mode_we;
	wire phy_config_tx_differential_mode_qs;
	wire phy_config_tx_differential_mode_wd;
	wire phy_config_tx_differential_mode_we;
	wire phy_config_eop_single_bit_qs;
	wire phy_config_eop_single_bit_wd;
	wire phy_config_eop_single_bit_we;
	wire phy_config_override_pwr_sense_en_qs;
	wire phy_config_override_pwr_sense_en_wd;
	wire phy_config_override_pwr_sense_en_we;
	wire phy_config_override_pwr_sense_val_qs;
	wire phy_config_override_pwr_sense_val_wd;
	wire phy_config_override_pwr_sense_val_we;
	prim_subreg #(
		.DW(1),
		.SWACCESS("W1C"),
		.RESVAL(1'h0)
	) u_intr_state_pkt_received(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(intr_state_pkt_received_we),
		.wd(intr_state_pkt_received_wd),
		.de(hw2reg[175]),
		.d(hw2reg[176]),
		.qe(),
		.q(reg2hw[343]),
		.qs(intr_state_pkt_received_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("W1C"),
		.RESVAL(1'h0)
	) u_intr_state_pkt_sent(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(intr_state_pkt_sent_we),
		.wd(intr_state_pkt_sent_wd),
		.de(hw2reg[173]),
		.d(hw2reg[174]),
		.qe(),
		.q(reg2hw[342]),
		.qs(intr_state_pkt_sent_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("W1C"),
		.RESVAL(1'h0)
	) u_intr_state_disconnected(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(intr_state_disconnected_we),
		.wd(intr_state_disconnected_wd),
		.de(hw2reg[171]),
		.d(hw2reg[172]),
		.qe(),
		.q(reg2hw[341]),
		.qs(intr_state_disconnected_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("W1C"),
		.RESVAL(1'h0)
	) u_intr_state_host_lost(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(intr_state_host_lost_we),
		.wd(intr_state_host_lost_wd),
		.de(hw2reg[169]),
		.d(hw2reg[170]),
		.qe(),
		.q(reg2hw[340]),
		.qs(intr_state_host_lost_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("W1C"),
		.RESVAL(1'h0)
	) u_intr_state_link_reset(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(intr_state_link_reset_we),
		.wd(intr_state_link_reset_wd),
		.de(hw2reg[167]),
		.d(hw2reg[168]),
		.qe(),
		.q(reg2hw[339]),
		.qs(intr_state_link_reset_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("W1C"),
		.RESVAL(1'h0)
	) u_intr_state_link_suspend(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(intr_state_link_suspend_we),
		.wd(intr_state_link_suspend_wd),
		.de(hw2reg[165]),
		.d(hw2reg[166]),
		.qe(),
		.q(reg2hw[338]),
		.qs(intr_state_link_suspend_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("W1C"),
		.RESVAL(1'h0)
	) u_intr_state_link_resume(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(intr_state_link_resume_we),
		.wd(intr_state_link_resume_wd),
		.de(hw2reg[163]),
		.d(hw2reg[164]),
		.qe(),
		.q(reg2hw[337]),
		.qs(intr_state_link_resume_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("W1C"),
		.RESVAL(1'h0)
	) u_intr_state_av_empty(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(intr_state_av_empty_we),
		.wd(intr_state_av_empty_wd),
		.de(hw2reg[161]),
		.d(hw2reg[162]),
		.qe(),
		.q(reg2hw[336]),
		.qs(intr_state_av_empty_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("W1C"),
		.RESVAL(1'h0)
	) u_intr_state_rx_full(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(intr_state_rx_full_we),
		.wd(intr_state_rx_full_wd),
		.de(hw2reg[159]),
		.d(hw2reg[160]),
		.qe(),
		.q(reg2hw[335]),
		.qs(intr_state_rx_full_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("W1C"),
		.RESVAL(1'h0)
	) u_intr_state_av_overflow(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(intr_state_av_overflow_we),
		.wd(intr_state_av_overflow_wd),
		.de(hw2reg[157]),
		.d(hw2reg[158]),
		.qe(),
		.q(reg2hw[334]),
		.qs(intr_state_av_overflow_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("W1C"),
		.RESVAL(1'h0)
	) u_intr_state_link_in_err(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(intr_state_link_in_err_we),
		.wd(intr_state_link_in_err_wd),
		.de(hw2reg[155]),
		.d(hw2reg[156]),
		.qe(),
		.q(reg2hw[333]),
		.qs(intr_state_link_in_err_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("W1C"),
		.RESVAL(1'h0)
	) u_intr_state_rx_crc_err(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(intr_state_rx_crc_err_we),
		.wd(intr_state_rx_crc_err_wd),
		.de(hw2reg[153]),
		.d(hw2reg[154]),
		.qe(),
		.q(reg2hw[332]),
		.qs(intr_state_rx_crc_err_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("W1C"),
		.RESVAL(1'h0)
	) u_intr_state_rx_pid_err(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(intr_state_rx_pid_err_we),
		.wd(intr_state_rx_pid_err_wd),
		.de(hw2reg[151]),
		.d(hw2reg[152]),
		.qe(),
		.q(reg2hw[331]),
		.qs(intr_state_rx_pid_err_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("W1C"),
		.RESVAL(1'h0)
	) u_intr_state_rx_bitstuff_err(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(intr_state_rx_bitstuff_err_we),
		.wd(intr_state_rx_bitstuff_err_wd),
		.de(hw2reg[149]),
		.d(hw2reg[150]),
		.qe(),
		.q(reg2hw[330]),
		.qs(intr_state_rx_bitstuff_err_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("W1C"),
		.RESVAL(1'h0)
	) u_intr_state_frame(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(intr_state_frame_we),
		.wd(intr_state_frame_wd),
		.de(hw2reg[147]),
		.d(hw2reg[148]),
		.qe(),
		.q(reg2hw[329]),
		.qs(intr_state_frame_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("W1C"),
		.RESVAL(1'h0)
	) u_intr_state_connected(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(intr_state_connected_we),
		.wd(intr_state_connected_wd),
		.de(hw2reg[145]),
		.d(hw2reg[146]),
		.qe(),
		.q(reg2hw[328]),
		.qs(intr_state_connected_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_intr_enable_pkt_received(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(intr_enable_pkt_received_we),
		.wd(intr_enable_pkt_received_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[327]),
		.qs(intr_enable_pkt_received_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_intr_enable_pkt_sent(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(intr_enable_pkt_sent_we),
		.wd(intr_enable_pkt_sent_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[326]),
		.qs(intr_enable_pkt_sent_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_intr_enable_disconnected(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(intr_enable_disconnected_we),
		.wd(intr_enable_disconnected_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[325]),
		.qs(intr_enable_disconnected_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_intr_enable_host_lost(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(intr_enable_host_lost_we),
		.wd(intr_enable_host_lost_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[324]),
		.qs(intr_enable_host_lost_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_intr_enable_link_reset(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(intr_enable_link_reset_we),
		.wd(intr_enable_link_reset_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[323]),
		.qs(intr_enable_link_reset_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_intr_enable_link_suspend(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(intr_enable_link_suspend_we),
		.wd(intr_enable_link_suspend_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[322]),
		.qs(intr_enable_link_suspend_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_intr_enable_link_resume(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(intr_enable_link_resume_we),
		.wd(intr_enable_link_resume_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[321]),
		.qs(intr_enable_link_resume_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_intr_enable_av_empty(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(intr_enable_av_empty_we),
		.wd(intr_enable_av_empty_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[320]),
		.qs(intr_enable_av_empty_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_intr_enable_rx_full(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(intr_enable_rx_full_we),
		.wd(intr_enable_rx_full_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[319]),
		.qs(intr_enable_rx_full_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_intr_enable_av_overflow(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(intr_enable_av_overflow_we),
		.wd(intr_enable_av_overflow_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[318]),
		.qs(intr_enable_av_overflow_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_intr_enable_link_in_err(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(intr_enable_link_in_err_we),
		.wd(intr_enable_link_in_err_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[317]),
		.qs(intr_enable_link_in_err_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_intr_enable_rx_crc_err(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(intr_enable_rx_crc_err_we),
		.wd(intr_enable_rx_crc_err_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[316]),
		.qs(intr_enable_rx_crc_err_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_intr_enable_rx_pid_err(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(intr_enable_rx_pid_err_we),
		.wd(intr_enable_rx_pid_err_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[315]),
		.qs(intr_enable_rx_pid_err_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_intr_enable_rx_bitstuff_err(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(intr_enable_rx_bitstuff_err_we),
		.wd(intr_enable_rx_bitstuff_err_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[314]),
		.qs(intr_enable_rx_bitstuff_err_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_intr_enable_frame(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(intr_enable_frame_we),
		.wd(intr_enable_frame_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[313]),
		.qs(intr_enable_frame_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_intr_enable_connected(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(intr_enable_connected_we),
		.wd(intr_enable_connected_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[312]),
		.qs(intr_enable_connected_qs)
	);
	prim_subreg_ext #(.DW(1)) u_intr_test_pkt_received(
		.re(1'b0),
		.we(intr_test_pkt_received_we),
		.wd(intr_test_pkt_received_wd),
		.d(1'sb0),
		.qre(),
		.qe(reg2hw[310]),
		.q(reg2hw[311]),
		.qs()
	);
	prim_subreg_ext #(.DW(1)) u_intr_test_pkt_sent(
		.re(1'b0),
		.we(intr_test_pkt_sent_we),
		.wd(intr_test_pkt_sent_wd),
		.d(1'sb0),
		.qre(),
		.qe(reg2hw[308]),
		.q(reg2hw[309]),
		.qs()
	);
	prim_subreg_ext #(.DW(1)) u_intr_test_disconnected(
		.re(1'b0),
		.we(intr_test_disconnected_we),
		.wd(intr_test_disconnected_wd),
		.d(1'sb0),
		.qre(),
		.qe(reg2hw[306]),
		.q(reg2hw[307]),
		.qs()
	);
	prim_subreg_ext #(.DW(1)) u_intr_test_host_lost(
		.re(1'b0),
		.we(intr_test_host_lost_we),
		.wd(intr_test_host_lost_wd),
		.d(1'sb0),
		.qre(),
		.qe(reg2hw[304]),
		.q(reg2hw[305]),
		.qs()
	);
	prim_subreg_ext #(.DW(1)) u_intr_test_link_reset(
		.re(1'b0),
		.we(intr_test_link_reset_we),
		.wd(intr_test_link_reset_wd),
		.d(1'sb0),
		.qre(),
		.qe(reg2hw[302]),
		.q(reg2hw[303]),
		.qs()
	);
	prim_subreg_ext #(.DW(1)) u_intr_test_link_suspend(
		.re(1'b0),
		.we(intr_test_link_suspend_we),
		.wd(intr_test_link_suspend_wd),
		.d(1'sb0),
		.qre(),
		.qe(reg2hw[300]),
		.q(reg2hw[301]),
		.qs()
	);
	prim_subreg_ext #(.DW(1)) u_intr_test_link_resume(
		.re(1'b0),
		.we(intr_test_link_resume_we),
		.wd(intr_test_link_resume_wd),
		.d(1'sb0),
		.qre(),
		.qe(reg2hw[298]),
		.q(reg2hw[299]),
		.qs()
	);
	prim_subreg_ext #(.DW(1)) u_intr_test_av_empty(
		.re(1'b0),
		.we(intr_test_av_empty_we),
		.wd(intr_test_av_empty_wd),
		.d(1'sb0),
		.qre(),
		.qe(reg2hw[296]),
		.q(reg2hw[297]),
		.qs()
	);
	prim_subreg_ext #(.DW(1)) u_intr_test_rx_full(
		.re(1'b0),
		.we(intr_test_rx_full_we),
		.wd(intr_test_rx_full_wd),
		.d(1'sb0),
		.qre(),
		.qe(reg2hw[294]),
		.q(reg2hw[295]),
		.qs()
	);
	prim_subreg_ext #(.DW(1)) u_intr_test_av_overflow(
		.re(1'b0),
		.we(intr_test_av_overflow_we),
		.wd(intr_test_av_overflow_wd),
		.d(1'sb0),
		.qre(),
		.qe(reg2hw[292]),
		.q(reg2hw[293]),
		.qs()
	);
	prim_subreg_ext #(.DW(1)) u_intr_test_link_in_err(
		.re(1'b0),
		.we(intr_test_link_in_err_we),
		.wd(intr_test_link_in_err_wd),
		.d(1'sb0),
		.qre(),
		.qe(reg2hw[290]),
		.q(reg2hw[291]),
		.qs()
	);
	prim_subreg_ext #(.DW(1)) u_intr_test_rx_crc_err(
		.re(1'b0),
		.we(intr_test_rx_crc_err_we),
		.wd(intr_test_rx_crc_err_wd),
		.d(1'sb0),
		.qre(),
		.qe(reg2hw[288]),
		.q(reg2hw[289]),
		.qs()
	);
	prim_subreg_ext #(.DW(1)) u_intr_test_rx_pid_err(
		.re(1'b0),
		.we(intr_test_rx_pid_err_we),
		.wd(intr_test_rx_pid_err_wd),
		.d(1'sb0),
		.qre(),
		.qe(reg2hw[286]),
		.q(reg2hw[287]),
		.qs()
	);
	prim_subreg_ext #(.DW(1)) u_intr_test_rx_bitstuff_err(
		.re(1'b0),
		.we(intr_test_rx_bitstuff_err_we),
		.wd(intr_test_rx_bitstuff_err_wd),
		.d(1'sb0),
		.qre(),
		.qe(reg2hw[284]),
		.q(reg2hw[285]),
		.qs()
	);
	prim_subreg_ext #(.DW(1)) u_intr_test_frame(
		.re(1'b0),
		.we(intr_test_frame_we),
		.wd(intr_test_frame_wd),
		.d(1'sb0),
		.qre(),
		.qe(reg2hw[282]),
		.q(reg2hw[283]),
		.qs()
	);
	prim_subreg_ext #(.DW(1)) u_intr_test_connected(
		.re(1'b0),
		.we(intr_test_connected_we),
		.wd(intr_test_connected_wd),
		.d(1'sb0),
		.qre(),
		.qe(reg2hw[280]),
		.q(reg2hw[281]),
		.qs()
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_usbctrl_enable(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(usbctrl_enable_we),
		.wd(usbctrl_enable_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[279]),
		.qs(usbctrl_enable_qs)
	);
	prim_subreg #(
		.DW(7),
		.SWACCESS("RW"),
		.RESVAL(7'h0)
	) u_usbctrl_device_address(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(usbctrl_device_address_we),
		.wd(usbctrl_device_address_wd),
		.de(hw2reg[137]),
		.d(hw2reg[144-:7]),
		.qe(),
		.q(reg2hw[278-:7]),
		.qs(usbctrl_device_address_qs)
	);
	prim_subreg_ext #(.DW(11)) u_usbstat_frame(
		.re(usbstat_frame_re),
		.we(1'b0),
		.wd(1'sb0),
		.d(hw2reg[136-:11]),
		.qre(),
		.qe(),
		.q(),
		.qs(usbstat_frame_qs)
	);
	prim_subreg_ext #(.DW(1)) u_usbstat_host_lost(
		.re(usbstat_host_lost_re),
		.we(1'b0),
		.wd(1'sb0),
		.d(hw2reg[125]),
		.qre(),
		.qe(),
		.q(),
		.qs(usbstat_host_lost_qs)
	);
	prim_subreg_ext #(.DW(3)) u_usbstat_link_state(
		.re(usbstat_link_state_re),
		.we(1'b0),
		.wd(1'sb0),
		.d(hw2reg[124-:3]),
		.qre(),
		.qe(),
		.q(),
		.qs(usbstat_link_state_qs)
	);
	prim_subreg_ext #(.DW(1)) u_usbstat_usb_sense(
		.re(usbstat_usb_sense_re),
		.we(1'b0),
		.wd(1'sb0),
		.d(hw2reg[121]),
		.qre(),
		.qe(),
		.q(),
		.qs(usbstat_usb_sense_qs)
	);
	prim_subreg_ext #(.DW(3)) u_usbstat_av_depth(
		.re(usbstat_av_depth_re),
		.we(1'b0),
		.wd(1'sb0),
		.d(hw2reg[120-:3]),
		.qre(),
		.qe(),
		.q(),
		.qs(usbstat_av_depth_qs)
	);
	prim_subreg_ext #(.DW(1)) u_usbstat_av_full(
		.re(usbstat_av_full_re),
		.we(1'b0),
		.wd(1'sb0),
		.d(hw2reg[117]),
		.qre(),
		.qe(),
		.q(),
		.qs(usbstat_av_full_qs)
	);
	prim_subreg_ext #(.DW(3)) u_usbstat_rx_depth(
		.re(usbstat_rx_depth_re),
		.we(1'b0),
		.wd(1'sb0),
		.d(hw2reg[116-:3]),
		.qre(),
		.qe(),
		.q(),
		.qs(usbstat_rx_depth_qs)
	);
	prim_subreg_ext #(.DW(1)) u_usbstat_rx_empty(
		.re(usbstat_rx_empty_re),
		.we(1'b0),
		.wd(1'sb0),
		.d(hw2reg[113]),
		.qre(),
		.qe(),
		.q(),
		.qs(usbstat_rx_empty_qs)
	);
	prim_subreg #(
		.DW(5),
		.SWACCESS("WO"),
		.RESVAL(5'h0)
	) u_avbuffer(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(avbuffer_we),
		.wd(avbuffer_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(reg2hw[266]),
		.q(reg2hw[271-:5]),
		.qs()
	);
	prim_subreg_ext #(.DW(5)) u_rxfifo_buffer(
		.re(rxfifo_buffer_re),
		.we(1'b0),
		.wd(1'sb0),
		.d(hw2reg[112-:5]),
		.qre(reg2hw[260]),
		.qe(),
		.q(reg2hw[265-:5]),
		.qs(rxfifo_buffer_qs)
	);
	prim_subreg_ext #(.DW(7)) u_rxfifo_size(
		.re(rxfifo_size_re),
		.we(1'b0),
		.wd(1'sb0),
		.d(hw2reg[107-:7]),
		.qre(reg2hw[252]),
		.qe(),
		.q(reg2hw[259-:7]),
		.qs(rxfifo_size_qs)
	);
	prim_subreg_ext #(.DW(1)) u_rxfifo_setup(
		.re(rxfifo_setup_re),
		.we(1'b0),
		.wd(1'sb0),
		.d(hw2reg[100]),
		.qre(reg2hw[250]),
		.qe(),
		.q(reg2hw[251]),
		.qs(rxfifo_setup_qs)
	);
	prim_subreg_ext #(.DW(4)) u_rxfifo_ep(
		.re(rxfifo_ep_re),
		.we(1'b0),
		.wd(1'sb0),
		.d(hw2reg[99-:4]),
		.qre(reg2hw[245]),
		.qe(),
		.q(reg2hw[249-:4]),
		.qs(rxfifo_ep_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_rxenable_setup_setup0(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(rxenable_setup_setup0_we),
		.wd(rxenable_setup_setup0_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[233]),
		.qs(rxenable_setup_setup0_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_rxenable_setup_setup1(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(rxenable_setup_setup1_we),
		.wd(rxenable_setup_setup1_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[234]),
		.qs(rxenable_setup_setup1_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_rxenable_setup_setup2(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(rxenable_setup_setup2_we),
		.wd(rxenable_setup_setup2_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[235]),
		.qs(rxenable_setup_setup2_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_rxenable_setup_setup3(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(rxenable_setup_setup3_we),
		.wd(rxenable_setup_setup3_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[236]),
		.qs(rxenable_setup_setup3_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_rxenable_setup_setup4(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(rxenable_setup_setup4_we),
		.wd(rxenable_setup_setup4_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[237]),
		.qs(rxenable_setup_setup4_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_rxenable_setup_setup5(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(rxenable_setup_setup5_we),
		.wd(rxenable_setup_setup5_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[238]),
		.qs(rxenable_setup_setup5_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_rxenable_setup_setup6(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(rxenable_setup_setup6_we),
		.wd(rxenable_setup_setup6_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[239]),
		.qs(rxenable_setup_setup6_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_rxenable_setup_setup7(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(rxenable_setup_setup7_we),
		.wd(rxenable_setup_setup7_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[240]),
		.qs(rxenable_setup_setup7_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_rxenable_setup_setup8(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(rxenable_setup_setup8_we),
		.wd(rxenable_setup_setup8_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[241]),
		.qs(rxenable_setup_setup8_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_rxenable_setup_setup9(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(rxenable_setup_setup9_we),
		.wd(rxenable_setup_setup9_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[242]),
		.qs(rxenable_setup_setup9_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_rxenable_setup_setup10(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(rxenable_setup_setup10_we),
		.wd(rxenable_setup_setup10_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[243]),
		.qs(rxenable_setup_setup10_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_rxenable_setup_setup11(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(rxenable_setup_setup11_we),
		.wd(rxenable_setup_setup11_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[244]),
		.qs(rxenable_setup_setup11_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_rxenable_out_out0(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(rxenable_out_out0_we),
		.wd(rxenable_out_out0_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[221]),
		.qs(rxenable_out_out0_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_rxenable_out_out1(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(rxenable_out_out1_we),
		.wd(rxenable_out_out1_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[222]),
		.qs(rxenable_out_out1_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_rxenable_out_out2(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(rxenable_out_out2_we),
		.wd(rxenable_out_out2_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[223]),
		.qs(rxenable_out_out2_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_rxenable_out_out3(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(rxenable_out_out3_we),
		.wd(rxenable_out_out3_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[224]),
		.qs(rxenable_out_out3_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_rxenable_out_out4(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(rxenable_out_out4_we),
		.wd(rxenable_out_out4_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[225]),
		.qs(rxenable_out_out4_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_rxenable_out_out5(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(rxenable_out_out5_we),
		.wd(rxenable_out_out5_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[226]),
		.qs(rxenable_out_out5_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_rxenable_out_out6(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(rxenable_out_out6_we),
		.wd(rxenable_out_out6_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[227]),
		.qs(rxenable_out_out6_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_rxenable_out_out7(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(rxenable_out_out7_we),
		.wd(rxenable_out_out7_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[228]),
		.qs(rxenable_out_out7_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_rxenable_out_out8(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(rxenable_out_out8_we),
		.wd(rxenable_out_out8_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[229]),
		.qs(rxenable_out_out8_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_rxenable_out_out9(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(rxenable_out_out9_we),
		.wd(rxenable_out_out9_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[230]),
		.qs(rxenable_out_out9_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_rxenable_out_out10(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(rxenable_out_out10_we),
		.wd(rxenable_out_out10_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[231]),
		.qs(rxenable_out_out10_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_rxenable_out_out11(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(rxenable_out_out11_we),
		.wd(rxenable_out_out11_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[232]),
		.qs(rxenable_out_out11_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("W1C"),
		.RESVAL(1'h0)
	) u_in_sent_sent0(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(in_sent_sent0_we),
		.wd(in_sent_sent0_wd),
		.de(hw2reg[72]),
		.d(hw2reg[73]),
		.qe(),
		.q(),
		.qs(in_sent_sent0_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("W1C"),
		.RESVAL(1'h0)
	) u_in_sent_sent1(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(in_sent_sent1_we),
		.wd(in_sent_sent1_wd),
		.de(hw2reg[74]),
		.d(hw2reg[75]),
		.qe(),
		.q(),
		.qs(in_sent_sent1_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("W1C"),
		.RESVAL(1'h0)
	) u_in_sent_sent2(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(in_sent_sent2_we),
		.wd(in_sent_sent2_wd),
		.de(hw2reg[76]),
		.d(hw2reg[77]),
		.qe(),
		.q(),
		.qs(in_sent_sent2_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("W1C"),
		.RESVAL(1'h0)
	) u_in_sent_sent3(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(in_sent_sent3_we),
		.wd(in_sent_sent3_wd),
		.de(hw2reg[78]),
		.d(hw2reg[79]),
		.qe(),
		.q(),
		.qs(in_sent_sent3_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("W1C"),
		.RESVAL(1'h0)
	) u_in_sent_sent4(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(in_sent_sent4_we),
		.wd(in_sent_sent4_wd),
		.de(hw2reg[80]),
		.d(hw2reg[81]),
		.qe(),
		.q(),
		.qs(in_sent_sent4_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("W1C"),
		.RESVAL(1'h0)
	) u_in_sent_sent5(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(in_sent_sent5_we),
		.wd(in_sent_sent5_wd),
		.de(hw2reg[82]),
		.d(hw2reg[83]),
		.qe(),
		.q(),
		.qs(in_sent_sent5_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("W1C"),
		.RESVAL(1'h0)
	) u_in_sent_sent6(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(in_sent_sent6_we),
		.wd(in_sent_sent6_wd),
		.de(hw2reg[84]),
		.d(hw2reg[85]),
		.qe(),
		.q(),
		.qs(in_sent_sent6_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("W1C"),
		.RESVAL(1'h0)
	) u_in_sent_sent7(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(in_sent_sent7_we),
		.wd(in_sent_sent7_wd),
		.de(hw2reg[86]),
		.d(hw2reg[87]),
		.qe(),
		.q(),
		.qs(in_sent_sent7_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("W1C"),
		.RESVAL(1'h0)
	) u_in_sent_sent8(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(in_sent_sent8_we),
		.wd(in_sent_sent8_wd),
		.de(hw2reg[88]),
		.d(hw2reg[89]),
		.qe(),
		.q(),
		.qs(in_sent_sent8_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("W1C"),
		.RESVAL(1'h0)
	) u_in_sent_sent9(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(in_sent_sent9_we),
		.wd(in_sent_sent9_wd),
		.de(hw2reg[90]),
		.d(hw2reg[91]),
		.qe(),
		.q(),
		.qs(in_sent_sent9_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("W1C"),
		.RESVAL(1'h0)
	) u_in_sent_sent10(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(in_sent_sent10_we),
		.wd(in_sent_sent10_wd),
		.de(hw2reg[92]),
		.d(hw2reg[93]),
		.qe(),
		.q(),
		.qs(in_sent_sent10_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("W1C"),
		.RESVAL(1'h0)
	) u_in_sent_sent11(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(in_sent_sent11_we),
		.wd(in_sent_sent11_wd),
		.de(hw2reg[94]),
		.d(hw2reg[95]),
		.qe(),
		.q(),
		.qs(in_sent_sent11_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_stall_stall0(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(stall_stall0_we),
		.wd(stall_stall0_wd),
		.de(hw2reg[48]),
		.d(hw2reg[49]),
		.qe(),
		.q(reg2hw[209]),
		.qs(stall_stall0_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_stall_stall1(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(stall_stall1_we),
		.wd(stall_stall1_wd),
		.de(hw2reg[50]),
		.d(hw2reg[51]),
		.qe(),
		.q(reg2hw[210]),
		.qs(stall_stall1_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_stall_stall2(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(stall_stall2_we),
		.wd(stall_stall2_wd),
		.de(hw2reg[52]),
		.d(hw2reg[53]),
		.qe(),
		.q(reg2hw[211]),
		.qs(stall_stall2_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_stall_stall3(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(stall_stall3_we),
		.wd(stall_stall3_wd),
		.de(hw2reg[54]),
		.d(hw2reg[55]),
		.qe(),
		.q(reg2hw[212]),
		.qs(stall_stall3_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_stall_stall4(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(stall_stall4_we),
		.wd(stall_stall4_wd),
		.de(hw2reg[56]),
		.d(hw2reg[57]),
		.qe(),
		.q(reg2hw[213]),
		.qs(stall_stall4_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_stall_stall5(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(stall_stall5_we),
		.wd(stall_stall5_wd),
		.de(hw2reg[58]),
		.d(hw2reg[59]),
		.qe(),
		.q(reg2hw[214]),
		.qs(stall_stall5_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_stall_stall6(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(stall_stall6_we),
		.wd(stall_stall6_wd),
		.de(hw2reg[60]),
		.d(hw2reg[61]),
		.qe(),
		.q(reg2hw[215]),
		.qs(stall_stall6_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_stall_stall7(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(stall_stall7_we),
		.wd(stall_stall7_wd),
		.de(hw2reg[62]),
		.d(hw2reg[63]),
		.qe(),
		.q(reg2hw[216]),
		.qs(stall_stall7_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_stall_stall8(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(stall_stall8_we),
		.wd(stall_stall8_wd),
		.de(hw2reg[64]),
		.d(hw2reg[65]),
		.qe(),
		.q(reg2hw[217]),
		.qs(stall_stall8_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_stall_stall9(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(stall_stall9_we),
		.wd(stall_stall9_wd),
		.de(hw2reg[66]),
		.d(hw2reg[67]),
		.qe(),
		.q(reg2hw[218]),
		.qs(stall_stall9_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_stall_stall10(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(stall_stall10_we),
		.wd(stall_stall10_wd),
		.de(hw2reg[68]),
		.d(hw2reg[69]),
		.qe(),
		.q(reg2hw[219]),
		.qs(stall_stall10_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_stall_stall11(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(stall_stall11_we),
		.wd(stall_stall11_wd),
		.de(hw2reg[70]),
		.d(hw2reg[71]),
		.qe(),
		.q(reg2hw[220]),
		.qs(stall_stall11_qs)
	);
	prim_subreg #(
		.DW(5),
		.SWACCESS("RW"),
		.RESVAL(5'h0)
	) u_configin0_buffer0(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(configin0_buffer0_we),
		.wd(configin0_buffer0_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[54-:5]),
		.qs(configin0_buffer0_qs)
	);
	prim_subreg #(
		.DW(7),
		.SWACCESS("RW"),
		.RESVAL(7'h0)
	) u_configin0_size0(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(configin0_size0_we),
		.wd(configin0_size0_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[49-:7]),
		.qs(configin0_size0_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("W1C"),
		.RESVAL(1'h0)
	) u_configin0_pend0(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(configin0_pend0_we),
		.wd(configin0_pend0_wd),
		.de(hw2reg[2]),
		.d(hw2reg[3]),
		.qe(),
		.q(reg2hw[42]),
		.qs(configin0_pend0_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_configin0_rdy0(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(configin0_rdy0_we),
		.wd(configin0_rdy0_wd),
		.de(hw2reg[0]),
		.d(hw2reg[1]),
		.qe(),
		.q(reg2hw[41]),
		.qs(configin0_rdy0_qs)
	);
	prim_subreg #(
		.DW(5),
		.SWACCESS("RW"),
		.RESVAL(5'h0)
	) u_configin1_buffer1(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(configin1_buffer1_we),
		.wd(configin1_buffer1_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[68-:5]),
		.qs(configin1_buffer1_qs)
	);
	prim_subreg #(
		.DW(7),
		.SWACCESS("RW"),
		.RESVAL(7'h0)
	) u_configin1_size1(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(configin1_size1_we),
		.wd(configin1_size1_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[63-:7]),
		.qs(configin1_size1_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("W1C"),
		.RESVAL(1'h0)
	) u_configin1_pend1(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(configin1_pend1_we),
		.wd(configin1_pend1_wd),
		.de(hw2reg[6]),
		.d(hw2reg[7]),
		.qe(),
		.q(reg2hw[56]),
		.qs(configin1_pend1_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_configin1_rdy1(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(configin1_rdy1_we),
		.wd(configin1_rdy1_wd),
		.de(hw2reg[4]),
		.d(hw2reg[5]),
		.qe(),
		.q(reg2hw[55]),
		.qs(configin1_rdy1_qs)
	);
	prim_subreg #(
		.DW(5),
		.SWACCESS("RW"),
		.RESVAL(5'h0)
	) u_configin2_buffer2(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(configin2_buffer2_we),
		.wd(configin2_buffer2_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[82-:5]),
		.qs(configin2_buffer2_qs)
	);
	prim_subreg #(
		.DW(7),
		.SWACCESS("RW"),
		.RESVAL(7'h0)
	) u_configin2_size2(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(configin2_size2_we),
		.wd(configin2_size2_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[77-:7]),
		.qs(configin2_size2_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("W1C"),
		.RESVAL(1'h0)
	) u_configin2_pend2(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(configin2_pend2_we),
		.wd(configin2_pend2_wd),
		.de(hw2reg[10]),
		.d(hw2reg[11]),
		.qe(),
		.q(reg2hw[70]),
		.qs(configin2_pend2_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_configin2_rdy2(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(configin2_rdy2_we),
		.wd(configin2_rdy2_wd),
		.de(hw2reg[8]),
		.d(hw2reg[9]),
		.qe(),
		.q(reg2hw[69]),
		.qs(configin2_rdy2_qs)
	);
	prim_subreg #(
		.DW(5),
		.SWACCESS("RW"),
		.RESVAL(5'h0)
	) u_configin3_buffer3(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(configin3_buffer3_we),
		.wd(configin3_buffer3_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[96-:5]),
		.qs(configin3_buffer3_qs)
	);
	prim_subreg #(
		.DW(7),
		.SWACCESS("RW"),
		.RESVAL(7'h0)
	) u_configin3_size3(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(configin3_size3_we),
		.wd(configin3_size3_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[91-:7]),
		.qs(configin3_size3_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("W1C"),
		.RESVAL(1'h0)
	) u_configin3_pend3(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(configin3_pend3_we),
		.wd(configin3_pend3_wd),
		.de(hw2reg[14]),
		.d(hw2reg[15]),
		.qe(),
		.q(reg2hw[84]),
		.qs(configin3_pend3_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_configin3_rdy3(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(configin3_rdy3_we),
		.wd(configin3_rdy3_wd),
		.de(hw2reg[12]),
		.d(hw2reg[13]),
		.qe(),
		.q(reg2hw[83]),
		.qs(configin3_rdy3_qs)
	);
	prim_subreg #(
		.DW(5),
		.SWACCESS("RW"),
		.RESVAL(5'h0)
	) u_configin4_buffer4(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(configin4_buffer4_we),
		.wd(configin4_buffer4_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[110-:5]),
		.qs(configin4_buffer4_qs)
	);
	prim_subreg #(
		.DW(7),
		.SWACCESS("RW"),
		.RESVAL(7'h0)
	) u_configin4_size4(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(configin4_size4_we),
		.wd(configin4_size4_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[105-:7]),
		.qs(configin4_size4_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("W1C"),
		.RESVAL(1'h0)
	) u_configin4_pend4(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(configin4_pend4_we),
		.wd(configin4_pend4_wd),
		.de(hw2reg[18]),
		.d(hw2reg[19]),
		.qe(),
		.q(reg2hw[98]),
		.qs(configin4_pend4_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_configin4_rdy4(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(configin4_rdy4_we),
		.wd(configin4_rdy4_wd),
		.de(hw2reg[16]),
		.d(hw2reg[17]),
		.qe(),
		.q(reg2hw[97]),
		.qs(configin4_rdy4_qs)
	);
	prim_subreg #(
		.DW(5),
		.SWACCESS("RW"),
		.RESVAL(5'h0)
	) u_configin5_buffer5(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(configin5_buffer5_we),
		.wd(configin5_buffer5_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[124-:5]),
		.qs(configin5_buffer5_qs)
	);
	prim_subreg #(
		.DW(7),
		.SWACCESS("RW"),
		.RESVAL(7'h0)
	) u_configin5_size5(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(configin5_size5_we),
		.wd(configin5_size5_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[119-:7]),
		.qs(configin5_size5_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("W1C"),
		.RESVAL(1'h0)
	) u_configin5_pend5(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(configin5_pend5_we),
		.wd(configin5_pend5_wd),
		.de(hw2reg[22]),
		.d(hw2reg[23]),
		.qe(),
		.q(reg2hw[112]),
		.qs(configin5_pend5_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_configin5_rdy5(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(configin5_rdy5_we),
		.wd(configin5_rdy5_wd),
		.de(hw2reg[20]),
		.d(hw2reg[21]),
		.qe(),
		.q(reg2hw[111]),
		.qs(configin5_rdy5_qs)
	);
	prim_subreg #(
		.DW(5),
		.SWACCESS("RW"),
		.RESVAL(5'h0)
	) u_configin6_buffer6(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(configin6_buffer6_we),
		.wd(configin6_buffer6_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[138-:5]),
		.qs(configin6_buffer6_qs)
	);
	prim_subreg #(
		.DW(7),
		.SWACCESS("RW"),
		.RESVAL(7'h0)
	) u_configin6_size6(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(configin6_size6_we),
		.wd(configin6_size6_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[133-:7]),
		.qs(configin6_size6_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("W1C"),
		.RESVAL(1'h0)
	) u_configin6_pend6(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(configin6_pend6_we),
		.wd(configin6_pend6_wd),
		.de(hw2reg[26]),
		.d(hw2reg[27]),
		.qe(),
		.q(reg2hw[126]),
		.qs(configin6_pend6_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_configin6_rdy6(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(configin6_rdy6_we),
		.wd(configin6_rdy6_wd),
		.de(hw2reg[24]),
		.d(hw2reg[25]),
		.qe(),
		.q(reg2hw[125]),
		.qs(configin6_rdy6_qs)
	);
	prim_subreg #(
		.DW(5),
		.SWACCESS("RW"),
		.RESVAL(5'h0)
	) u_configin7_buffer7(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(configin7_buffer7_we),
		.wd(configin7_buffer7_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[152-:5]),
		.qs(configin7_buffer7_qs)
	);
	prim_subreg #(
		.DW(7),
		.SWACCESS("RW"),
		.RESVAL(7'h0)
	) u_configin7_size7(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(configin7_size7_we),
		.wd(configin7_size7_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[147-:7]),
		.qs(configin7_size7_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("W1C"),
		.RESVAL(1'h0)
	) u_configin7_pend7(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(configin7_pend7_we),
		.wd(configin7_pend7_wd),
		.de(hw2reg[30]),
		.d(hw2reg[31]),
		.qe(),
		.q(reg2hw[140]),
		.qs(configin7_pend7_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_configin7_rdy7(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(configin7_rdy7_we),
		.wd(configin7_rdy7_wd),
		.de(hw2reg[28]),
		.d(hw2reg[29]),
		.qe(),
		.q(reg2hw[139]),
		.qs(configin7_rdy7_qs)
	);
	prim_subreg #(
		.DW(5),
		.SWACCESS("RW"),
		.RESVAL(5'h0)
	) u_configin8_buffer8(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(configin8_buffer8_we),
		.wd(configin8_buffer8_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[166-:5]),
		.qs(configin8_buffer8_qs)
	);
	prim_subreg #(
		.DW(7),
		.SWACCESS("RW"),
		.RESVAL(7'h0)
	) u_configin8_size8(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(configin8_size8_we),
		.wd(configin8_size8_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[161-:7]),
		.qs(configin8_size8_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("W1C"),
		.RESVAL(1'h0)
	) u_configin8_pend8(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(configin8_pend8_we),
		.wd(configin8_pend8_wd),
		.de(hw2reg[34]),
		.d(hw2reg[35]),
		.qe(),
		.q(reg2hw[154]),
		.qs(configin8_pend8_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_configin8_rdy8(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(configin8_rdy8_we),
		.wd(configin8_rdy8_wd),
		.de(hw2reg[32]),
		.d(hw2reg[33]),
		.qe(),
		.q(reg2hw[153]),
		.qs(configin8_rdy8_qs)
	);
	prim_subreg #(
		.DW(5),
		.SWACCESS("RW"),
		.RESVAL(5'h0)
	) u_configin9_buffer9(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(configin9_buffer9_we),
		.wd(configin9_buffer9_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[180-:5]),
		.qs(configin9_buffer9_qs)
	);
	prim_subreg #(
		.DW(7),
		.SWACCESS("RW"),
		.RESVAL(7'h0)
	) u_configin9_size9(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(configin9_size9_we),
		.wd(configin9_size9_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[175-:7]),
		.qs(configin9_size9_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("W1C"),
		.RESVAL(1'h0)
	) u_configin9_pend9(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(configin9_pend9_we),
		.wd(configin9_pend9_wd),
		.de(hw2reg[38]),
		.d(hw2reg[39]),
		.qe(),
		.q(reg2hw[168]),
		.qs(configin9_pend9_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_configin9_rdy9(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(configin9_rdy9_we),
		.wd(configin9_rdy9_wd),
		.de(hw2reg[36]),
		.d(hw2reg[37]),
		.qe(),
		.q(reg2hw[167]),
		.qs(configin9_rdy9_qs)
	);
	prim_subreg #(
		.DW(5),
		.SWACCESS("RW"),
		.RESVAL(5'h0)
	) u_configin10_buffer10(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(configin10_buffer10_we),
		.wd(configin10_buffer10_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[194-:5]),
		.qs(configin10_buffer10_qs)
	);
	prim_subreg #(
		.DW(7),
		.SWACCESS("RW"),
		.RESVAL(7'h0)
	) u_configin10_size10(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(configin10_size10_we),
		.wd(configin10_size10_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[189-:7]),
		.qs(configin10_size10_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("W1C"),
		.RESVAL(1'h0)
	) u_configin10_pend10(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(configin10_pend10_we),
		.wd(configin10_pend10_wd),
		.de(hw2reg[42]),
		.d(hw2reg[43]),
		.qe(),
		.q(reg2hw[182]),
		.qs(configin10_pend10_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_configin10_rdy10(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(configin10_rdy10_we),
		.wd(configin10_rdy10_wd),
		.de(hw2reg[40]),
		.d(hw2reg[41]),
		.qe(),
		.q(reg2hw[181]),
		.qs(configin10_rdy10_qs)
	);
	prim_subreg #(
		.DW(5),
		.SWACCESS("RW"),
		.RESVAL(5'h0)
	) u_configin11_buffer11(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(configin11_buffer11_we),
		.wd(configin11_buffer11_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[208-:5]),
		.qs(configin11_buffer11_qs)
	);
	prim_subreg #(
		.DW(7),
		.SWACCESS("RW"),
		.RESVAL(7'h0)
	) u_configin11_size11(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(configin11_size11_we),
		.wd(configin11_size11_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[203-:7]),
		.qs(configin11_size11_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("W1C"),
		.RESVAL(1'h0)
	) u_configin11_pend11(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(configin11_pend11_we),
		.wd(configin11_pend11_wd),
		.de(hw2reg[46]),
		.d(hw2reg[47]),
		.qe(),
		.q(reg2hw[196]),
		.qs(configin11_pend11_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_configin11_rdy11(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(configin11_rdy11_we),
		.wd(configin11_rdy11_wd),
		.de(hw2reg[44]),
		.d(hw2reg[45]),
		.qe(),
		.q(reg2hw[195]),
		.qs(configin11_rdy11_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_iso_iso0(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(iso_iso0_we),
		.wd(iso_iso0_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[29]),
		.qs(iso_iso0_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_iso_iso1(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(iso_iso1_we),
		.wd(iso_iso1_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[30]),
		.qs(iso_iso1_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_iso_iso2(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(iso_iso2_we),
		.wd(iso_iso2_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[31]),
		.qs(iso_iso2_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_iso_iso3(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(iso_iso3_we),
		.wd(iso_iso3_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[32]),
		.qs(iso_iso3_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_iso_iso4(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(iso_iso4_we),
		.wd(iso_iso4_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[33]),
		.qs(iso_iso4_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_iso_iso5(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(iso_iso5_we),
		.wd(iso_iso5_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[34]),
		.qs(iso_iso5_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_iso_iso6(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(iso_iso6_we),
		.wd(iso_iso6_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[35]),
		.qs(iso_iso6_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_iso_iso7(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(iso_iso7_we),
		.wd(iso_iso7_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[36]),
		.qs(iso_iso7_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_iso_iso8(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(iso_iso8_we),
		.wd(iso_iso8_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[37]),
		.qs(iso_iso8_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_iso_iso9(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(iso_iso9_we),
		.wd(iso_iso9_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[38]),
		.qs(iso_iso9_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_iso_iso10(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(iso_iso10_we),
		.wd(iso_iso10_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[39]),
		.qs(iso_iso10_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_iso_iso11(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(iso_iso11_we),
		.wd(iso_iso11_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[40]),
		.qs(iso_iso11_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("WO"),
		.RESVAL(1'h0)
	) u_data_toggle_clear_clear0(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(data_toggle_clear_clear0_we),
		.wd(data_toggle_clear_clear0_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(reg2hw[5]),
		.q(reg2hw[6]),
		.qs()
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("WO"),
		.RESVAL(1'h0)
	) u_data_toggle_clear_clear1(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(data_toggle_clear_clear1_we),
		.wd(data_toggle_clear_clear1_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(reg2hw[7]),
		.q(reg2hw[8]),
		.qs()
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("WO"),
		.RESVAL(1'h0)
	) u_data_toggle_clear_clear2(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(data_toggle_clear_clear2_we),
		.wd(data_toggle_clear_clear2_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(reg2hw[9]),
		.q(reg2hw[10]),
		.qs()
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("WO"),
		.RESVAL(1'h0)
	) u_data_toggle_clear_clear3(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(data_toggle_clear_clear3_we),
		.wd(data_toggle_clear_clear3_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(reg2hw[11]),
		.q(reg2hw[12]),
		.qs()
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("WO"),
		.RESVAL(1'h0)
	) u_data_toggle_clear_clear4(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(data_toggle_clear_clear4_we),
		.wd(data_toggle_clear_clear4_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(reg2hw[13]),
		.q(reg2hw[14]),
		.qs()
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("WO"),
		.RESVAL(1'h0)
	) u_data_toggle_clear_clear5(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(data_toggle_clear_clear5_we),
		.wd(data_toggle_clear_clear5_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(reg2hw[15]),
		.q(reg2hw[16]),
		.qs()
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("WO"),
		.RESVAL(1'h0)
	) u_data_toggle_clear_clear6(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(data_toggle_clear_clear6_we),
		.wd(data_toggle_clear_clear6_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(reg2hw[17]),
		.q(reg2hw[18]),
		.qs()
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("WO"),
		.RESVAL(1'h0)
	) u_data_toggle_clear_clear7(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(data_toggle_clear_clear7_we),
		.wd(data_toggle_clear_clear7_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(reg2hw[19]),
		.q(reg2hw[20]),
		.qs()
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("WO"),
		.RESVAL(1'h0)
	) u_data_toggle_clear_clear8(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(data_toggle_clear_clear8_we),
		.wd(data_toggle_clear_clear8_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(reg2hw[21]),
		.q(reg2hw[22]),
		.qs()
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("WO"),
		.RESVAL(1'h0)
	) u_data_toggle_clear_clear9(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(data_toggle_clear_clear9_we),
		.wd(data_toggle_clear_clear9_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(reg2hw[23]),
		.q(reg2hw[24]),
		.qs()
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("WO"),
		.RESVAL(1'h0)
	) u_data_toggle_clear_clear10(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(data_toggle_clear_clear10_we),
		.wd(data_toggle_clear_clear10_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(reg2hw[25]),
		.q(reg2hw[26]),
		.qs()
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("WO"),
		.RESVAL(1'h0)
	) u_data_toggle_clear_clear11(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(data_toggle_clear_clear11_we),
		.wd(data_toggle_clear_clear11_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(reg2hw[27]),
		.q(reg2hw[28]),
		.qs()
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_phy_config_rx_differential_mode(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(phy_config_rx_differential_mode_we),
		.wd(phy_config_rx_differential_mode_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[4]),
		.qs(phy_config_rx_differential_mode_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_phy_config_tx_differential_mode(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(phy_config_tx_differential_mode_we),
		.wd(phy_config_tx_differential_mode_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[3]),
		.qs(phy_config_tx_differential_mode_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h1)
	) u_phy_config_eop_single_bit(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(phy_config_eop_single_bit_we),
		.wd(phy_config_eop_single_bit_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[2]),
		.qs(phy_config_eop_single_bit_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_phy_config_override_pwr_sense_en(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(phy_config_override_pwr_sense_en_we),
		.wd(phy_config_override_pwr_sense_en_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[1]),
		.qs(phy_config_override_pwr_sense_en_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_phy_config_override_pwr_sense_val(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(phy_config_override_pwr_sense_val_we),
		.wd(phy_config_override_pwr_sense_val_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[0]),
		.qs(phy_config_override_pwr_sense_val_qs)
	);
	reg [25:0] addr_hit;
	always @(*) begin
		addr_hit = 1'sb0;
		addr_hit[0] = reg_addr == USBDEV_INTR_STATE_OFFSET;
		addr_hit[1] = reg_addr == USBDEV_INTR_ENABLE_OFFSET;
		addr_hit[2] = reg_addr == USBDEV_INTR_TEST_OFFSET;
		addr_hit[3] = reg_addr == USBDEV_USBCTRL_OFFSET;
		addr_hit[4] = reg_addr == USBDEV_USBSTAT_OFFSET;
		addr_hit[5] = reg_addr == USBDEV_AVBUFFER_OFFSET;
		addr_hit[6] = reg_addr == USBDEV_RXFIFO_OFFSET;
		addr_hit[7] = reg_addr == USBDEV_RXENABLE_SETUP_OFFSET;
		addr_hit[8] = reg_addr == USBDEV_RXENABLE_OUT_OFFSET;
		addr_hit[9] = reg_addr == USBDEV_IN_SENT_OFFSET;
		addr_hit[10] = reg_addr == USBDEV_STALL_OFFSET;
		addr_hit[11] = reg_addr == USBDEV_CONFIGIN0_OFFSET;
		addr_hit[12] = reg_addr == USBDEV_CONFIGIN1_OFFSET;
		addr_hit[13] = reg_addr == USBDEV_CONFIGIN2_OFFSET;
		addr_hit[14] = reg_addr == USBDEV_CONFIGIN3_OFFSET;
		addr_hit[15] = reg_addr == USBDEV_CONFIGIN4_OFFSET;
		addr_hit[16] = reg_addr == USBDEV_CONFIGIN5_OFFSET;
		addr_hit[17] = reg_addr == USBDEV_CONFIGIN6_OFFSET;
		addr_hit[18] = reg_addr == USBDEV_CONFIGIN7_OFFSET;
		addr_hit[19] = reg_addr == USBDEV_CONFIGIN8_OFFSET;
		addr_hit[20] = reg_addr == USBDEV_CONFIGIN9_OFFSET;
		addr_hit[21] = reg_addr == USBDEV_CONFIGIN10_OFFSET;
		addr_hit[22] = reg_addr == USBDEV_CONFIGIN11_OFFSET;
		addr_hit[23] = reg_addr == USBDEV_ISO_OFFSET;
		addr_hit[24] = reg_addr == USBDEV_DATA_TOGGLE_CLEAR_OFFSET;
		addr_hit[25] = reg_addr == USBDEV_PHY_CONFIG_OFFSET;
	end
	assign addrmiss = (reg_re || reg_we ? ~|addr_hit : 1'b0);
	always @(*) begin
		wr_err = 1'b0;
		if ((addr_hit[0] && reg_we) && (USBDEV_PERMIT[100+:4] != (USBDEV_PERMIT[100+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[1] && reg_we) && (USBDEV_PERMIT[96+:4] != (USBDEV_PERMIT[96+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[2] && reg_we) && (USBDEV_PERMIT[92+:4] != (USBDEV_PERMIT[92+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[3] && reg_we) && (USBDEV_PERMIT[88+:4] != (USBDEV_PERMIT[88+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[4] && reg_we) && (USBDEV_PERMIT[84+:4] != (USBDEV_PERMIT[84+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[5] && reg_we) && (USBDEV_PERMIT[80+:4] != (USBDEV_PERMIT[80+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[6] && reg_we) && (USBDEV_PERMIT[76+:4] != (USBDEV_PERMIT[76+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[7] && reg_we) && (USBDEV_PERMIT[72+:4] != (USBDEV_PERMIT[72+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[8] && reg_we) && (USBDEV_PERMIT[68+:4] != (USBDEV_PERMIT[68+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[9] && reg_we) && (USBDEV_PERMIT[64+:4] != (USBDEV_PERMIT[64+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[10] && reg_we) && (USBDEV_PERMIT[60+:4] != (USBDEV_PERMIT[60+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[11] && reg_we) && (USBDEV_PERMIT[56+:4] != (USBDEV_PERMIT[56+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[12] && reg_we) && (USBDEV_PERMIT[52+:4] != (USBDEV_PERMIT[52+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[13] && reg_we) && (USBDEV_PERMIT[48+:4] != (USBDEV_PERMIT[48+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[14] && reg_we) && (USBDEV_PERMIT[44+:4] != (USBDEV_PERMIT[44+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[15] && reg_we) && (USBDEV_PERMIT[40+:4] != (USBDEV_PERMIT[40+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[16] && reg_we) && (USBDEV_PERMIT[36+:4] != (USBDEV_PERMIT[36+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[17] && reg_we) && (USBDEV_PERMIT[32+:4] != (USBDEV_PERMIT[32+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[18] && reg_we) && (USBDEV_PERMIT[28+:4] != (USBDEV_PERMIT[28+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[19] && reg_we) && (USBDEV_PERMIT[24+:4] != (USBDEV_PERMIT[24+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[20] && reg_we) && (USBDEV_PERMIT[20+:4] != (USBDEV_PERMIT[20+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[21] && reg_we) && (USBDEV_PERMIT[16+:4] != (USBDEV_PERMIT[16+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[22] && reg_we) && (USBDEV_PERMIT[12+:4] != (USBDEV_PERMIT[12+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[23] && reg_we) && (USBDEV_PERMIT[8+:4] != (USBDEV_PERMIT[8+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[24] && reg_we) && (USBDEV_PERMIT[4+:4] != (USBDEV_PERMIT[4+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[25] && reg_we) && (USBDEV_PERMIT[0+:4] != (USBDEV_PERMIT[0+:4] & reg_be)))
			wr_err = 1'b1;
	end
	assign intr_state_pkt_received_we = (addr_hit[0] & reg_we) & ~wr_err;
	assign intr_state_pkt_received_wd = reg_wdata[0];
	assign intr_state_pkt_sent_we = (addr_hit[0] & reg_we) & ~wr_err;
	assign intr_state_pkt_sent_wd = reg_wdata[1];
	assign intr_state_disconnected_we = (addr_hit[0] & reg_we) & ~wr_err;
	assign intr_state_disconnected_wd = reg_wdata[2];
	assign intr_state_host_lost_we = (addr_hit[0] & reg_we) & ~wr_err;
	assign intr_state_host_lost_wd = reg_wdata[3];
	assign intr_state_link_reset_we = (addr_hit[0] & reg_we) & ~wr_err;
	assign intr_state_link_reset_wd = reg_wdata[4];
	assign intr_state_link_suspend_we = (addr_hit[0] & reg_we) & ~wr_err;
	assign intr_state_link_suspend_wd = reg_wdata[5];
	assign intr_state_link_resume_we = (addr_hit[0] & reg_we) & ~wr_err;
	assign intr_state_link_resume_wd = reg_wdata[6];
	assign intr_state_av_empty_we = (addr_hit[0] & reg_we) & ~wr_err;
	assign intr_state_av_empty_wd = reg_wdata[7];
	assign intr_state_rx_full_we = (addr_hit[0] & reg_we) & ~wr_err;
	assign intr_state_rx_full_wd = reg_wdata[8];
	assign intr_state_av_overflow_we = (addr_hit[0] & reg_we) & ~wr_err;
	assign intr_state_av_overflow_wd = reg_wdata[9];
	assign intr_state_link_in_err_we = (addr_hit[0] & reg_we) & ~wr_err;
	assign intr_state_link_in_err_wd = reg_wdata[10];
	assign intr_state_rx_crc_err_we = (addr_hit[0] & reg_we) & ~wr_err;
	assign intr_state_rx_crc_err_wd = reg_wdata[11];
	assign intr_state_rx_pid_err_we = (addr_hit[0] & reg_we) & ~wr_err;
	assign intr_state_rx_pid_err_wd = reg_wdata[12];
	assign intr_state_rx_bitstuff_err_we = (addr_hit[0] & reg_we) & ~wr_err;
	assign intr_state_rx_bitstuff_err_wd = reg_wdata[13];
	assign intr_state_frame_we = (addr_hit[0] & reg_we) & ~wr_err;
	assign intr_state_frame_wd = reg_wdata[14];
	assign intr_state_connected_we = (addr_hit[0] & reg_we) & ~wr_err;
	assign intr_state_connected_wd = reg_wdata[15];
	assign intr_enable_pkt_received_we = (addr_hit[1] & reg_we) & ~wr_err;
	assign intr_enable_pkt_received_wd = reg_wdata[0];
	assign intr_enable_pkt_sent_we = (addr_hit[1] & reg_we) & ~wr_err;
	assign intr_enable_pkt_sent_wd = reg_wdata[1];
	assign intr_enable_disconnected_we = (addr_hit[1] & reg_we) & ~wr_err;
	assign intr_enable_disconnected_wd = reg_wdata[2];
	assign intr_enable_host_lost_we = (addr_hit[1] & reg_we) & ~wr_err;
	assign intr_enable_host_lost_wd = reg_wdata[3];
	assign intr_enable_link_reset_we = (addr_hit[1] & reg_we) & ~wr_err;
	assign intr_enable_link_reset_wd = reg_wdata[4];
	assign intr_enable_link_suspend_we = (addr_hit[1] & reg_we) & ~wr_err;
	assign intr_enable_link_suspend_wd = reg_wdata[5];
	assign intr_enable_link_resume_we = (addr_hit[1] & reg_we) & ~wr_err;
	assign intr_enable_link_resume_wd = reg_wdata[6];
	assign intr_enable_av_empty_we = (addr_hit[1] & reg_we) & ~wr_err;
	assign intr_enable_av_empty_wd = reg_wdata[7];
	assign intr_enable_rx_full_we = (addr_hit[1] & reg_we) & ~wr_err;
	assign intr_enable_rx_full_wd = reg_wdata[8];
	assign intr_enable_av_overflow_we = (addr_hit[1] & reg_we) & ~wr_err;
	assign intr_enable_av_overflow_wd = reg_wdata[9];
	assign intr_enable_link_in_err_we = (addr_hit[1] & reg_we) & ~wr_err;
	assign intr_enable_link_in_err_wd = reg_wdata[10];
	assign intr_enable_rx_crc_err_we = (addr_hit[1] & reg_we) & ~wr_err;
	assign intr_enable_rx_crc_err_wd = reg_wdata[11];
	assign intr_enable_rx_pid_err_we = (addr_hit[1] & reg_we) & ~wr_err;
	assign intr_enable_rx_pid_err_wd = reg_wdata[12];
	assign intr_enable_rx_bitstuff_err_we = (addr_hit[1] & reg_we) & ~wr_err;
	assign intr_enable_rx_bitstuff_err_wd = reg_wdata[13];
	assign intr_enable_frame_we = (addr_hit[1] & reg_we) & ~wr_err;
	assign intr_enable_frame_wd = reg_wdata[14];
	assign intr_enable_connected_we = (addr_hit[1] & reg_we) & ~wr_err;
	assign intr_enable_connected_wd = reg_wdata[15];
	assign intr_test_pkt_received_we = (addr_hit[2] & reg_we) & ~wr_err;
	assign intr_test_pkt_received_wd = reg_wdata[0];
	assign intr_test_pkt_sent_we = (addr_hit[2] & reg_we) & ~wr_err;
	assign intr_test_pkt_sent_wd = reg_wdata[1];
	assign intr_test_disconnected_we = (addr_hit[2] & reg_we) & ~wr_err;
	assign intr_test_disconnected_wd = reg_wdata[2];
	assign intr_test_host_lost_we = (addr_hit[2] & reg_we) & ~wr_err;
	assign intr_test_host_lost_wd = reg_wdata[3];
	assign intr_test_link_reset_we = (addr_hit[2] & reg_we) & ~wr_err;
	assign intr_test_link_reset_wd = reg_wdata[4];
	assign intr_test_link_suspend_we = (addr_hit[2] & reg_we) & ~wr_err;
	assign intr_test_link_suspend_wd = reg_wdata[5];
	assign intr_test_link_resume_we = (addr_hit[2] & reg_we) & ~wr_err;
	assign intr_test_link_resume_wd = reg_wdata[6];
	assign intr_test_av_empty_we = (addr_hit[2] & reg_we) & ~wr_err;
	assign intr_test_av_empty_wd = reg_wdata[7];
	assign intr_test_rx_full_we = (addr_hit[2] & reg_we) & ~wr_err;
	assign intr_test_rx_full_wd = reg_wdata[8];
	assign intr_test_av_overflow_we = (addr_hit[2] & reg_we) & ~wr_err;
	assign intr_test_av_overflow_wd = reg_wdata[9];
	assign intr_test_link_in_err_we = (addr_hit[2] & reg_we) & ~wr_err;
	assign intr_test_link_in_err_wd = reg_wdata[10];
	assign intr_test_rx_crc_err_we = (addr_hit[2] & reg_we) & ~wr_err;
	assign intr_test_rx_crc_err_wd = reg_wdata[11];
	assign intr_test_rx_pid_err_we = (addr_hit[2] & reg_we) & ~wr_err;
	assign intr_test_rx_pid_err_wd = reg_wdata[12];
	assign intr_test_rx_bitstuff_err_we = (addr_hit[2] & reg_we) & ~wr_err;
	assign intr_test_rx_bitstuff_err_wd = reg_wdata[13];
	assign intr_test_frame_we = (addr_hit[2] & reg_we) & ~wr_err;
	assign intr_test_frame_wd = reg_wdata[14];
	assign intr_test_connected_we = (addr_hit[2] & reg_we) & ~wr_err;
	assign intr_test_connected_wd = reg_wdata[15];
	assign usbctrl_enable_we = (addr_hit[3] & reg_we) & ~wr_err;
	assign usbctrl_enable_wd = reg_wdata[0];
	assign usbctrl_device_address_we = (addr_hit[3] & reg_we) & ~wr_err;
	assign usbctrl_device_address_wd = reg_wdata[22:16];
	assign usbstat_frame_re = addr_hit[4] && reg_re;
	assign usbstat_host_lost_re = addr_hit[4] && reg_re;
	assign usbstat_link_state_re = addr_hit[4] && reg_re;
	assign usbstat_usb_sense_re = addr_hit[4] && reg_re;
	assign usbstat_av_depth_re = addr_hit[4] && reg_re;
	assign usbstat_av_full_re = addr_hit[4] && reg_re;
	assign usbstat_rx_depth_re = addr_hit[4] && reg_re;
	assign usbstat_rx_empty_re = addr_hit[4] && reg_re;
	assign avbuffer_we = (addr_hit[5] & reg_we) & ~wr_err;
	assign avbuffer_wd = reg_wdata[4:0];
	assign rxfifo_buffer_re = addr_hit[6] && reg_re;
	assign rxfifo_size_re = addr_hit[6] && reg_re;
	assign rxfifo_setup_re = addr_hit[6] && reg_re;
	assign rxfifo_ep_re = addr_hit[6] && reg_re;
	assign rxenable_setup_setup0_we = (addr_hit[7] & reg_we) & ~wr_err;
	assign rxenable_setup_setup0_wd = reg_wdata[0];
	assign rxenable_setup_setup1_we = (addr_hit[7] & reg_we) & ~wr_err;
	assign rxenable_setup_setup1_wd = reg_wdata[1];
	assign rxenable_setup_setup2_we = (addr_hit[7] & reg_we) & ~wr_err;
	assign rxenable_setup_setup2_wd = reg_wdata[2];
	assign rxenable_setup_setup3_we = (addr_hit[7] & reg_we) & ~wr_err;
	assign rxenable_setup_setup3_wd = reg_wdata[3];
	assign rxenable_setup_setup4_we = (addr_hit[7] & reg_we) & ~wr_err;
	assign rxenable_setup_setup4_wd = reg_wdata[4];
	assign rxenable_setup_setup5_we = (addr_hit[7] & reg_we) & ~wr_err;
	assign rxenable_setup_setup5_wd = reg_wdata[5];
	assign rxenable_setup_setup6_we = (addr_hit[7] & reg_we) & ~wr_err;
	assign rxenable_setup_setup6_wd = reg_wdata[6];
	assign rxenable_setup_setup7_we = (addr_hit[7] & reg_we) & ~wr_err;
	assign rxenable_setup_setup7_wd = reg_wdata[7];
	assign rxenable_setup_setup8_we = (addr_hit[7] & reg_we) & ~wr_err;
	assign rxenable_setup_setup8_wd = reg_wdata[8];
	assign rxenable_setup_setup9_we = (addr_hit[7] & reg_we) & ~wr_err;
	assign rxenable_setup_setup9_wd = reg_wdata[9];
	assign rxenable_setup_setup10_we = (addr_hit[7] & reg_we) & ~wr_err;
	assign rxenable_setup_setup10_wd = reg_wdata[10];
	assign rxenable_setup_setup11_we = (addr_hit[7] & reg_we) & ~wr_err;
	assign rxenable_setup_setup11_wd = reg_wdata[11];
	assign rxenable_out_out0_we = (addr_hit[8] & reg_we) & ~wr_err;
	assign rxenable_out_out0_wd = reg_wdata[0];
	assign rxenable_out_out1_we = (addr_hit[8] & reg_we) & ~wr_err;
	assign rxenable_out_out1_wd = reg_wdata[1];
	assign rxenable_out_out2_we = (addr_hit[8] & reg_we) & ~wr_err;
	assign rxenable_out_out2_wd = reg_wdata[2];
	assign rxenable_out_out3_we = (addr_hit[8] & reg_we) & ~wr_err;
	assign rxenable_out_out3_wd = reg_wdata[3];
	assign rxenable_out_out4_we = (addr_hit[8] & reg_we) & ~wr_err;
	assign rxenable_out_out4_wd = reg_wdata[4];
	assign rxenable_out_out5_we = (addr_hit[8] & reg_we) & ~wr_err;
	assign rxenable_out_out5_wd = reg_wdata[5];
	assign rxenable_out_out6_we = (addr_hit[8] & reg_we) & ~wr_err;
	assign rxenable_out_out6_wd = reg_wdata[6];
	assign rxenable_out_out7_we = (addr_hit[8] & reg_we) & ~wr_err;
	assign rxenable_out_out7_wd = reg_wdata[7];
	assign rxenable_out_out8_we = (addr_hit[8] & reg_we) & ~wr_err;
	assign rxenable_out_out8_wd = reg_wdata[8];
	assign rxenable_out_out9_we = (addr_hit[8] & reg_we) & ~wr_err;
	assign rxenable_out_out9_wd = reg_wdata[9];
	assign rxenable_out_out10_we = (addr_hit[8] & reg_we) & ~wr_err;
	assign rxenable_out_out10_wd = reg_wdata[10];
	assign rxenable_out_out11_we = (addr_hit[8] & reg_we) & ~wr_err;
	assign rxenable_out_out11_wd = reg_wdata[11];
	assign in_sent_sent0_we = (addr_hit[9] & reg_we) & ~wr_err;
	assign in_sent_sent0_wd = reg_wdata[0];
	assign in_sent_sent1_we = (addr_hit[9] & reg_we) & ~wr_err;
	assign in_sent_sent1_wd = reg_wdata[1];
	assign in_sent_sent2_we = (addr_hit[9] & reg_we) & ~wr_err;
	assign in_sent_sent2_wd = reg_wdata[2];
	assign in_sent_sent3_we = (addr_hit[9] & reg_we) & ~wr_err;
	assign in_sent_sent3_wd = reg_wdata[3];
	assign in_sent_sent4_we = (addr_hit[9] & reg_we) & ~wr_err;
	assign in_sent_sent4_wd = reg_wdata[4];
	assign in_sent_sent5_we = (addr_hit[9] & reg_we) & ~wr_err;
	assign in_sent_sent5_wd = reg_wdata[5];
	assign in_sent_sent6_we = (addr_hit[9] & reg_we) & ~wr_err;
	assign in_sent_sent6_wd = reg_wdata[6];
	assign in_sent_sent7_we = (addr_hit[9] & reg_we) & ~wr_err;
	assign in_sent_sent7_wd = reg_wdata[7];
	assign in_sent_sent8_we = (addr_hit[9] & reg_we) & ~wr_err;
	assign in_sent_sent8_wd = reg_wdata[8];
	assign in_sent_sent9_we = (addr_hit[9] & reg_we) & ~wr_err;
	assign in_sent_sent9_wd = reg_wdata[9];
	assign in_sent_sent10_we = (addr_hit[9] & reg_we) & ~wr_err;
	assign in_sent_sent10_wd = reg_wdata[10];
	assign in_sent_sent11_we = (addr_hit[9] & reg_we) & ~wr_err;
	assign in_sent_sent11_wd = reg_wdata[11];
	assign stall_stall0_we = (addr_hit[10] & reg_we) & ~wr_err;
	assign stall_stall0_wd = reg_wdata[0];
	assign stall_stall1_we = (addr_hit[10] & reg_we) & ~wr_err;
	assign stall_stall1_wd = reg_wdata[1];
	assign stall_stall2_we = (addr_hit[10] & reg_we) & ~wr_err;
	assign stall_stall2_wd = reg_wdata[2];
	assign stall_stall3_we = (addr_hit[10] & reg_we) & ~wr_err;
	assign stall_stall3_wd = reg_wdata[3];
	assign stall_stall4_we = (addr_hit[10] & reg_we) & ~wr_err;
	assign stall_stall4_wd = reg_wdata[4];
	assign stall_stall5_we = (addr_hit[10] & reg_we) & ~wr_err;
	assign stall_stall5_wd = reg_wdata[5];
	assign stall_stall6_we = (addr_hit[10] & reg_we) & ~wr_err;
	assign stall_stall6_wd = reg_wdata[6];
	assign stall_stall7_we = (addr_hit[10] & reg_we) & ~wr_err;
	assign stall_stall7_wd = reg_wdata[7];
	assign stall_stall8_we = (addr_hit[10] & reg_we) & ~wr_err;
	assign stall_stall8_wd = reg_wdata[8];
	assign stall_stall9_we = (addr_hit[10] & reg_we) & ~wr_err;
	assign stall_stall9_wd = reg_wdata[9];
	assign stall_stall10_we = (addr_hit[10] & reg_we) & ~wr_err;
	assign stall_stall10_wd = reg_wdata[10];
	assign stall_stall11_we = (addr_hit[10] & reg_we) & ~wr_err;
	assign stall_stall11_wd = reg_wdata[11];
	assign configin0_buffer0_we = (addr_hit[11] & reg_we) & ~wr_err;
	assign configin0_buffer0_wd = reg_wdata[4:0];
	assign configin0_size0_we = (addr_hit[11] & reg_we) & ~wr_err;
	assign configin0_size0_wd = reg_wdata[14:8];
	assign configin0_pend0_we = (addr_hit[11] & reg_we) & ~wr_err;
	assign configin0_pend0_wd = reg_wdata[30];
	assign configin0_rdy0_we = (addr_hit[11] & reg_we) & ~wr_err;
	assign configin0_rdy0_wd = reg_wdata[31];
	assign configin1_buffer1_we = (addr_hit[12] & reg_we) & ~wr_err;
	assign configin1_buffer1_wd = reg_wdata[4:0];
	assign configin1_size1_we = (addr_hit[12] & reg_we) & ~wr_err;
	assign configin1_size1_wd = reg_wdata[14:8];
	assign configin1_pend1_we = (addr_hit[12] & reg_we) & ~wr_err;
	assign configin1_pend1_wd = reg_wdata[30];
	assign configin1_rdy1_we = (addr_hit[12] & reg_we) & ~wr_err;
	assign configin1_rdy1_wd = reg_wdata[31];
	assign configin2_buffer2_we = (addr_hit[13] & reg_we) & ~wr_err;
	assign configin2_buffer2_wd = reg_wdata[4:0];
	assign configin2_size2_we = (addr_hit[13] & reg_we) & ~wr_err;
	assign configin2_size2_wd = reg_wdata[14:8];
	assign configin2_pend2_we = (addr_hit[13] & reg_we) & ~wr_err;
	assign configin2_pend2_wd = reg_wdata[30];
	assign configin2_rdy2_we = (addr_hit[13] & reg_we) & ~wr_err;
	assign configin2_rdy2_wd = reg_wdata[31];
	assign configin3_buffer3_we = (addr_hit[14] & reg_we) & ~wr_err;
	assign configin3_buffer3_wd = reg_wdata[4:0];
	assign configin3_size3_we = (addr_hit[14] & reg_we) & ~wr_err;
	assign configin3_size3_wd = reg_wdata[14:8];
	assign configin3_pend3_we = (addr_hit[14] & reg_we) & ~wr_err;
	assign configin3_pend3_wd = reg_wdata[30];
	assign configin3_rdy3_we = (addr_hit[14] & reg_we) & ~wr_err;
	assign configin3_rdy3_wd = reg_wdata[31];
	assign configin4_buffer4_we = (addr_hit[15] & reg_we) & ~wr_err;
	assign configin4_buffer4_wd = reg_wdata[4:0];
	assign configin4_size4_we = (addr_hit[15] & reg_we) & ~wr_err;
	assign configin4_size4_wd = reg_wdata[14:8];
	assign configin4_pend4_we = (addr_hit[15] & reg_we) & ~wr_err;
	assign configin4_pend4_wd = reg_wdata[30];
	assign configin4_rdy4_we = (addr_hit[15] & reg_we) & ~wr_err;
	assign configin4_rdy4_wd = reg_wdata[31];
	assign configin5_buffer5_we = (addr_hit[16] & reg_we) & ~wr_err;
	assign configin5_buffer5_wd = reg_wdata[4:0];
	assign configin5_size5_we = (addr_hit[16] & reg_we) & ~wr_err;
	assign configin5_size5_wd = reg_wdata[14:8];
	assign configin5_pend5_we = (addr_hit[16] & reg_we) & ~wr_err;
	assign configin5_pend5_wd = reg_wdata[30];
	assign configin5_rdy5_we = (addr_hit[16] & reg_we) & ~wr_err;
	assign configin5_rdy5_wd = reg_wdata[31];
	assign configin6_buffer6_we = (addr_hit[17] & reg_we) & ~wr_err;
	assign configin6_buffer6_wd = reg_wdata[4:0];
	assign configin6_size6_we = (addr_hit[17] & reg_we) & ~wr_err;
	assign configin6_size6_wd = reg_wdata[14:8];
	assign configin6_pend6_we = (addr_hit[17] & reg_we) & ~wr_err;
	assign configin6_pend6_wd = reg_wdata[30];
	assign configin6_rdy6_we = (addr_hit[17] & reg_we) & ~wr_err;
	assign configin6_rdy6_wd = reg_wdata[31];
	assign configin7_buffer7_we = (addr_hit[18] & reg_we) & ~wr_err;
	assign configin7_buffer7_wd = reg_wdata[4:0];
	assign configin7_size7_we = (addr_hit[18] & reg_we) & ~wr_err;
	assign configin7_size7_wd = reg_wdata[14:8];
	assign configin7_pend7_we = (addr_hit[18] & reg_we) & ~wr_err;
	assign configin7_pend7_wd = reg_wdata[30];
	assign configin7_rdy7_we = (addr_hit[18] & reg_we) & ~wr_err;
	assign configin7_rdy7_wd = reg_wdata[31];
	assign configin8_buffer8_we = (addr_hit[19] & reg_we) & ~wr_err;
	assign configin8_buffer8_wd = reg_wdata[4:0];
	assign configin8_size8_we = (addr_hit[19] & reg_we) & ~wr_err;
	assign configin8_size8_wd = reg_wdata[14:8];
	assign configin8_pend8_we = (addr_hit[19] & reg_we) & ~wr_err;
	assign configin8_pend8_wd = reg_wdata[30];
	assign configin8_rdy8_we = (addr_hit[19] & reg_we) & ~wr_err;
	assign configin8_rdy8_wd = reg_wdata[31];
	assign configin9_buffer9_we = (addr_hit[20] & reg_we) & ~wr_err;
	assign configin9_buffer9_wd = reg_wdata[4:0];
	assign configin9_size9_we = (addr_hit[20] & reg_we) & ~wr_err;
	assign configin9_size9_wd = reg_wdata[14:8];
	assign configin9_pend9_we = (addr_hit[20] & reg_we) & ~wr_err;
	assign configin9_pend9_wd = reg_wdata[30];
	assign configin9_rdy9_we = (addr_hit[20] & reg_we) & ~wr_err;
	assign configin9_rdy9_wd = reg_wdata[31];
	assign configin10_buffer10_we = (addr_hit[21] & reg_we) & ~wr_err;
	assign configin10_buffer10_wd = reg_wdata[4:0];
	assign configin10_size10_we = (addr_hit[21] & reg_we) & ~wr_err;
	assign configin10_size10_wd = reg_wdata[14:8];
	assign configin10_pend10_we = (addr_hit[21] & reg_we) & ~wr_err;
	assign configin10_pend10_wd = reg_wdata[30];
	assign configin10_rdy10_we = (addr_hit[21] & reg_we) & ~wr_err;
	assign configin10_rdy10_wd = reg_wdata[31];
	assign configin11_buffer11_we = (addr_hit[22] & reg_we) & ~wr_err;
	assign configin11_buffer11_wd = reg_wdata[4:0];
	assign configin11_size11_we = (addr_hit[22] & reg_we) & ~wr_err;
	assign configin11_size11_wd = reg_wdata[14:8];
	assign configin11_pend11_we = (addr_hit[22] & reg_we) & ~wr_err;
	assign configin11_pend11_wd = reg_wdata[30];
	assign configin11_rdy11_we = (addr_hit[22] & reg_we) & ~wr_err;
	assign configin11_rdy11_wd = reg_wdata[31];
	assign iso_iso0_we = (addr_hit[23] & reg_we) & ~wr_err;
	assign iso_iso0_wd = reg_wdata[0];
	assign iso_iso1_we = (addr_hit[23] & reg_we) & ~wr_err;
	assign iso_iso1_wd = reg_wdata[1];
	assign iso_iso2_we = (addr_hit[23] & reg_we) & ~wr_err;
	assign iso_iso2_wd = reg_wdata[2];
	assign iso_iso3_we = (addr_hit[23] & reg_we) & ~wr_err;
	assign iso_iso3_wd = reg_wdata[3];
	assign iso_iso4_we = (addr_hit[23] & reg_we) & ~wr_err;
	assign iso_iso4_wd = reg_wdata[4];
	assign iso_iso5_we = (addr_hit[23] & reg_we) & ~wr_err;
	assign iso_iso5_wd = reg_wdata[5];
	assign iso_iso6_we = (addr_hit[23] & reg_we) & ~wr_err;
	assign iso_iso6_wd = reg_wdata[6];
	assign iso_iso7_we = (addr_hit[23] & reg_we) & ~wr_err;
	assign iso_iso7_wd = reg_wdata[7];
	assign iso_iso8_we = (addr_hit[23] & reg_we) & ~wr_err;
	assign iso_iso8_wd = reg_wdata[8];
	assign iso_iso9_we = (addr_hit[23] & reg_we) & ~wr_err;
	assign iso_iso9_wd = reg_wdata[9];
	assign iso_iso10_we = (addr_hit[23] & reg_we) & ~wr_err;
	assign iso_iso10_wd = reg_wdata[10];
	assign iso_iso11_we = (addr_hit[23] & reg_we) & ~wr_err;
	assign iso_iso11_wd = reg_wdata[11];
	assign data_toggle_clear_clear0_we = (addr_hit[24] & reg_we) & ~wr_err;
	assign data_toggle_clear_clear0_wd = reg_wdata[0];
	assign data_toggle_clear_clear1_we = (addr_hit[24] & reg_we) & ~wr_err;
	assign data_toggle_clear_clear1_wd = reg_wdata[1];
	assign data_toggle_clear_clear2_we = (addr_hit[24] & reg_we) & ~wr_err;
	assign data_toggle_clear_clear2_wd = reg_wdata[2];
	assign data_toggle_clear_clear3_we = (addr_hit[24] & reg_we) & ~wr_err;
	assign data_toggle_clear_clear3_wd = reg_wdata[3];
	assign data_toggle_clear_clear4_we = (addr_hit[24] & reg_we) & ~wr_err;
	assign data_toggle_clear_clear4_wd = reg_wdata[4];
	assign data_toggle_clear_clear5_we = (addr_hit[24] & reg_we) & ~wr_err;
	assign data_toggle_clear_clear5_wd = reg_wdata[5];
	assign data_toggle_clear_clear6_we = (addr_hit[24] & reg_we) & ~wr_err;
	assign data_toggle_clear_clear6_wd = reg_wdata[6];
	assign data_toggle_clear_clear7_we = (addr_hit[24] & reg_we) & ~wr_err;
	assign data_toggle_clear_clear7_wd = reg_wdata[7];
	assign data_toggle_clear_clear8_we = (addr_hit[24] & reg_we) & ~wr_err;
	assign data_toggle_clear_clear8_wd = reg_wdata[8];
	assign data_toggle_clear_clear9_we = (addr_hit[24] & reg_we) & ~wr_err;
	assign data_toggle_clear_clear9_wd = reg_wdata[9];
	assign data_toggle_clear_clear10_we = (addr_hit[24] & reg_we) & ~wr_err;
	assign data_toggle_clear_clear10_wd = reg_wdata[10];
	assign data_toggle_clear_clear11_we = (addr_hit[24] & reg_we) & ~wr_err;
	assign data_toggle_clear_clear11_wd = reg_wdata[11];
	assign phy_config_rx_differential_mode_we = (addr_hit[25] & reg_we) & ~wr_err;
	assign phy_config_rx_differential_mode_wd = reg_wdata[0];
	assign phy_config_tx_differential_mode_we = (addr_hit[25] & reg_we) & ~wr_err;
	assign phy_config_tx_differential_mode_wd = reg_wdata[1];
	assign phy_config_eop_single_bit_we = (addr_hit[25] & reg_we) & ~wr_err;
	assign phy_config_eop_single_bit_wd = reg_wdata[2];
	assign phy_config_override_pwr_sense_en_we = (addr_hit[25] & reg_we) & ~wr_err;
	assign phy_config_override_pwr_sense_en_wd = reg_wdata[3];
	assign phy_config_override_pwr_sense_val_we = (addr_hit[25] & reg_we) & ~wr_err;
	assign phy_config_override_pwr_sense_val_wd = reg_wdata[4];
	always @(*) begin
		reg_rdata_next = 1'sb0;
		case (1'b1)
			addr_hit[0]: begin
				reg_rdata_next[0] = intr_state_pkt_received_qs;
				reg_rdata_next[1] = intr_state_pkt_sent_qs;
				reg_rdata_next[2] = intr_state_disconnected_qs;
				reg_rdata_next[3] = intr_state_host_lost_qs;
				reg_rdata_next[4] = intr_state_link_reset_qs;
				reg_rdata_next[5] = intr_state_link_suspend_qs;
				reg_rdata_next[6] = intr_state_link_resume_qs;
				reg_rdata_next[7] = intr_state_av_empty_qs;
				reg_rdata_next[8] = intr_state_rx_full_qs;
				reg_rdata_next[9] = intr_state_av_overflow_qs;
				reg_rdata_next[10] = intr_state_link_in_err_qs;
				reg_rdata_next[11] = intr_state_rx_crc_err_qs;
				reg_rdata_next[12] = intr_state_rx_pid_err_qs;
				reg_rdata_next[13] = intr_state_rx_bitstuff_err_qs;
				reg_rdata_next[14] = intr_state_frame_qs;
				reg_rdata_next[15] = intr_state_connected_qs;
			end
			addr_hit[1]: begin
				reg_rdata_next[0] = intr_enable_pkt_received_qs;
				reg_rdata_next[1] = intr_enable_pkt_sent_qs;
				reg_rdata_next[2] = intr_enable_disconnected_qs;
				reg_rdata_next[3] = intr_enable_host_lost_qs;
				reg_rdata_next[4] = intr_enable_link_reset_qs;
				reg_rdata_next[5] = intr_enable_link_suspend_qs;
				reg_rdata_next[6] = intr_enable_link_resume_qs;
				reg_rdata_next[7] = intr_enable_av_empty_qs;
				reg_rdata_next[8] = intr_enable_rx_full_qs;
				reg_rdata_next[9] = intr_enable_av_overflow_qs;
				reg_rdata_next[10] = intr_enable_link_in_err_qs;
				reg_rdata_next[11] = intr_enable_rx_crc_err_qs;
				reg_rdata_next[12] = intr_enable_rx_pid_err_qs;
				reg_rdata_next[13] = intr_enable_rx_bitstuff_err_qs;
				reg_rdata_next[14] = intr_enable_frame_qs;
				reg_rdata_next[15] = intr_enable_connected_qs;
			end
			addr_hit[2]: begin
				reg_rdata_next[0] = 1'sb0;
				reg_rdata_next[1] = 1'sb0;
				reg_rdata_next[2] = 1'sb0;
				reg_rdata_next[3] = 1'sb0;
				reg_rdata_next[4] = 1'sb0;
				reg_rdata_next[5] = 1'sb0;
				reg_rdata_next[6] = 1'sb0;
				reg_rdata_next[7] = 1'sb0;
				reg_rdata_next[8] = 1'sb0;
				reg_rdata_next[9] = 1'sb0;
				reg_rdata_next[10] = 1'sb0;
				reg_rdata_next[11] = 1'sb0;
				reg_rdata_next[12] = 1'sb0;
				reg_rdata_next[13] = 1'sb0;
				reg_rdata_next[14] = 1'sb0;
				reg_rdata_next[15] = 1'sb0;
			end
			addr_hit[3]: begin
				reg_rdata_next[0] = usbctrl_enable_qs;
				reg_rdata_next[22:16] = usbctrl_device_address_qs;
			end
			addr_hit[4]: begin
				reg_rdata_next[10:0] = usbstat_frame_qs;
				reg_rdata_next[11] = usbstat_host_lost_qs;
				reg_rdata_next[14:12] = usbstat_link_state_qs;
				reg_rdata_next[15] = usbstat_usb_sense_qs;
				reg_rdata_next[18:16] = usbstat_av_depth_qs;
				reg_rdata_next[23] = usbstat_av_full_qs;
				reg_rdata_next[26:24] = usbstat_rx_depth_qs;
				reg_rdata_next[31] = usbstat_rx_empty_qs;
			end
			addr_hit[5]: reg_rdata_next[4:0] = 1'sb0;
			addr_hit[6]: begin
				reg_rdata_next[4:0] = rxfifo_buffer_qs;
				reg_rdata_next[14:8] = rxfifo_size_qs;
				reg_rdata_next[19] = rxfifo_setup_qs;
				reg_rdata_next[23:20] = rxfifo_ep_qs;
			end
			addr_hit[7]: begin
				reg_rdata_next[0] = rxenable_setup_setup0_qs;
				reg_rdata_next[1] = rxenable_setup_setup1_qs;
				reg_rdata_next[2] = rxenable_setup_setup2_qs;
				reg_rdata_next[3] = rxenable_setup_setup3_qs;
				reg_rdata_next[4] = rxenable_setup_setup4_qs;
				reg_rdata_next[5] = rxenable_setup_setup5_qs;
				reg_rdata_next[6] = rxenable_setup_setup6_qs;
				reg_rdata_next[7] = rxenable_setup_setup7_qs;
				reg_rdata_next[8] = rxenable_setup_setup8_qs;
				reg_rdata_next[9] = rxenable_setup_setup9_qs;
				reg_rdata_next[10] = rxenable_setup_setup10_qs;
				reg_rdata_next[11] = rxenable_setup_setup11_qs;
			end
			addr_hit[8]: begin
				reg_rdata_next[0] = rxenable_out_out0_qs;
				reg_rdata_next[1] = rxenable_out_out1_qs;
				reg_rdata_next[2] = rxenable_out_out2_qs;
				reg_rdata_next[3] = rxenable_out_out3_qs;
				reg_rdata_next[4] = rxenable_out_out4_qs;
				reg_rdata_next[5] = rxenable_out_out5_qs;
				reg_rdata_next[6] = rxenable_out_out6_qs;
				reg_rdata_next[7] = rxenable_out_out7_qs;
				reg_rdata_next[8] = rxenable_out_out8_qs;
				reg_rdata_next[9] = rxenable_out_out9_qs;
				reg_rdata_next[10] = rxenable_out_out10_qs;
				reg_rdata_next[11] = rxenable_out_out11_qs;
			end
			addr_hit[9]: begin
				reg_rdata_next[0] = in_sent_sent0_qs;
				reg_rdata_next[1] = in_sent_sent1_qs;
				reg_rdata_next[2] = in_sent_sent2_qs;
				reg_rdata_next[3] = in_sent_sent3_qs;
				reg_rdata_next[4] = in_sent_sent4_qs;
				reg_rdata_next[5] = in_sent_sent5_qs;
				reg_rdata_next[6] = in_sent_sent6_qs;
				reg_rdata_next[7] = in_sent_sent7_qs;
				reg_rdata_next[8] = in_sent_sent8_qs;
				reg_rdata_next[9] = in_sent_sent9_qs;
				reg_rdata_next[10] = in_sent_sent10_qs;
				reg_rdata_next[11] = in_sent_sent11_qs;
			end
			addr_hit[10]: begin
				reg_rdata_next[0] = stall_stall0_qs;
				reg_rdata_next[1] = stall_stall1_qs;
				reg_rdata_next[2] = stall_stall2_qs;
				reg_rdata_next[3] = stall_stall3_qs;
				reg_rdata_next[4] = stall_stall4_qs;
				reg_rdata_next[5] = stall_stall5_qs;
				reg_rdata_next[6] = stall_stall6_qs;
				reg_rdata_next[7] = stall_stall7_qs;
				reg_rdata_next[8] = stall_stall8_qs;
				reg_rdata_next[9] = stall_stall9_qs;
				reg_rdata_next[10] = stall_stall10_qs;
				reg_rdata_next[11] = stall_stall11_qs;
			end
			addr_hit[11]: begin
				reg_rdata_next[4:0] = configin0_buffer0_qs;
				reg_rdata_next[14:8] = configin0_size0_qs;
				reg_rdata_next[30] = configin0_pend0_qs;
				reg_rdata_next[31] = configin0_rdy0_qs;
			end
			addr_hit[12]: begin
				reg_rdata_next[4:0] = configin1_buffer1_qs;
				reg_rdata_next[14:8] = configin1_size1_qs;
				reg_rdata_next[30] = configin1_pend1_qs;
				reg_rdata_next[31] = configin1_rdy1_qs;
			end
			addr_hit[13]: begin
				reg_rdata_next[4:0] = configin2_buffer2_qs;
				reg_rdata_next[14:8] = configin2_size2_qs;
				reg_rdata_next[30] = configin2_pend2_qs;
				reg_rdata_next[31] = configin2_rdy2_qs;
			end
			addr_hit[14]: begin
				reg_rdata_next[4:0] = configin3_buffer3_qs;
				reg_rdata_next[14:8] = configin3_size3_qs;
				reg_rdata_next[30] = configin3_pend3_qs;
				reg_rdata_next[31] = configin3_rdy3_qs;
			end
			addr_hit[15]: begin
				reg_rdata_next[4:0] = configin4_buffer4_qs;
				reg_rdata_next[14:8] = configin4_size4_qs;
				reg_rdata_next[30] = configin4_pend4_qs;
				reg_rdata_next[31] = configin4_rdy4_qs;
			end
			addr_hit[16]: begin
				reg_rdata_next[4:0] = configin5_buffer5_qs;
				reg_rdata_next[14:8] = configin5_size5_qs;
				reg_rdata_next[30] = configin5_pend5_qs;
				reg_rdata_next[31] = configin5_rdy5_qs;
			end
			addr_hit[17]: begin
				reg_rdata_next[4:0] = configin6_buffer6_qs;
				reg_rdata_next[14:8] = configin6_size6_qs;
				reg_rdata_next[30] = configin6_pend6_qs;
				reg_rdata_next[31] = configin6_rdy6_qs;
			end
			addr_hit[18]: begin
				reg_rdata_next[4:0] = configin7_buffer7_qs;
				reg_rdata_next[14:8] = configin7_size7_qs;
				reg_rdata_next[30] = configin7_pend7_qs;
				reg_rdata_next[31] = configin7_rdy7_qs;
			end
			addr_hit[19]: begin
				reg_rdata_next[4:0] = configin8_buffer8_qs;
				reg_rdata_next[14:8] = configin8_size8_qs;
				reg_rdata_next[30] = configin8_pend8_qs;
				reg_rdata_next[31] = configin8_rdy8_qs;
			end
			addr_hit[20]: begin
				reg_rdata_next[4:0] = configin9_buffer9_qs;
				reg_rdata_next[14:8] = configin9_size9_qs;
				reg_rdata_next[30] = configin9_pend9_qs;
				reg_rdata_next[31] = configin9_rdy9_qs;
			end
			addr_hit[21]: begin
				reg_rdata_next[4:0] = configin10_buffer10_qs;
				reg_rdata_next[14:8] = configin10_size10_qs;
				reg_rdata_next[30] = configin10_pend10_qs;
				reg_rdata_next[31] = configin10_rdy10_qs;
			end
			addr_hit[22]: begin
				reg_rdata_next[4:0] = configin11_buffer11_qs;
				reg_rdata_next[14:8] = configin11_size11_qs;
				reg_rdata_next[30] = configin11_pend11_qs;
				reg_rdata_next[31] = configin11_rdy11_qs;
			end
			addr_hit[23]: begin
				reg_rdata_next[0] = iso_iso0_qs;
				reg_rdata_next[1] = iso_iso1_qs;
				reg_rdata_next[2] = iso_iso2_qs;
				reg_rdata_next[3] = iso_iso3_qs;
				reg_rdata_next[4] = iso_iso4_qs;
				reg_rdata_next[5] = iso_iso5_qs;
				reg_rdata_next[6] = iso_iso6_qs;
				reg_rdata_next[7] = iso_iso7_qs;
				reg_rdata_next[8] = iso_iso8_qs;
				reg_rdata_next[9] = iso_iso9_qs;
				reg_rdata_next[10] = iso_iso10_qs;
				reg_rdata_next[11] = iso_iso11_qs;
			end
			addr_hit[24]: begin
				reg_rdata_next[0] = 1'sb0;
				reg_rdata_next[1] = 1'sb0;
				reg_rdata_next[2] = 1'sb0;
				reg_rdata_next[3] = 1'sb0;
				reg_rdata_next[4] = 1'sb0;
				reg_rdata_next[5] = 1'sb0;
				reg_rdata_next[6] = 1'sb0;
				reg_rdata_next[7] = 1'sb0;
				reg_rdata_next[8] = 1'sb0;
				reg_rdata_next[9] = 1'sb0;
				reg_rdata_next[10] = 1'sb0;
				reg_rdata_next[11] = 1'sb0;
			end
			addr_hit[25]: begin
				reg_rdata_next[0] = phy_config_rx_differential_mode_qs;
				reg_rdata_next[1] = phy_config_tx_differential_mode_qs;
				reg_rdata_next[2] = phy_config_eop_single_bit_qs;
				reg_rdata_next[3] = phy_config_override_pwr_sense_en_qs;
				reg_rdata_next[4] = phy_config_override_pwr_sense_val_qs;
			end
			default: reg_rdata_next = 1'sb1;
		endcase
	end
endmodule
