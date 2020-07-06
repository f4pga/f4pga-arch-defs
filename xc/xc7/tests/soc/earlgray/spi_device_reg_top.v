module spi_device_reg_top (
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
	output wire [168:0] reg2hw;
	input wire [67:0] hw2reg;
	input devmode_i;
	parameter [11:0] SPI_DEVICE_INTR_STATE_OFFSET = 12'h 0;
	parameter [11:0] SPI_DEVICE_INTR_ENABLE_OFFSET = 12'h 4;
	parameter [11:0] SPI_DEVICE_INTR_TEST_OFFSET = 12'h 8;
	parameter [11:0] SPI_DEVICE_CONTROL_OFFSET = 12'h c;
	parameter [11:0] SPI_DEVICE_CFG_OFFSET = 12'h 10;
	parameter [11:0] SPI_DEVICE_FIFO_LEVEL_OFFSET = 12'h 14;
	parameter [11:0] SPI_DEVICE_ASYNC_FIFO_LEVEL_OFFSET = 12'h 18;
	parameter [11:0] SPI_DEVICE_STATUS_OFFSET = 12'h 1c;
	parameter [11:0] SPI_DEVICE_RXF_PTR_OFFSET = 12'h 20;
	parameter [11:0] SPI_DEVICE_TXF_PTR_OFFSET = 12'h 24;
	parameter [11:0] SPI_DEVICE_RXF_ADDR_OFFSET = 12'h 28;
	parameter [11:0] SPI_DEVICE_TXF_ADDR_OFFSET = 12'h 2c;
	parameter [11:0] SPI_DEVICE_BUFFER_OFFSET = 12'h 800;
	parameter [11:0] SPI_DEVICE_BUFFER_SIZE = 12'h 800;
	parameter [47:0] SPI_DEVICE_PERMIT = {4'b 0001, 4'b 0001, 4'b 0001, 4'b 0111, 4'b 0011, 4'b 1111, 4'b 0111, 4'b 0001, 4'b 1111, 4'b 1111, 4'b 1111, 4'b 1111};
	localparam SPI_DEVICE_INTR_STATE = 0;
	localparam SPI_DEVICE_INTR_ENABLE = 1;
	localparam SPI_DEVICE_RXF_ADDR = 10;
	localparam SPI_DEVICE_TXF_ADDR = 11;
	localparam SPI_DEVICE_INTR_TEST = 2;
	localparam SPI_DEVICE_CONTROL = 3;
	localparam SPI_DEVICE_CFG = 4;
	localparam SPI_DEVICE_FIFO_LEVEL = 5;
	localparam SPI_DEVICE_ASYNC_FIFO_LEVEL = 6;
	localparam SPI_DEVICE_STATUS = 7;
	localparam SPI_DEVICE_RXF_PTR = 8;
	localparam SPI_DEVICE_TXF_PTR = 9;
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
	wire intr_state_rxf_qs;
	wire intr_state_rxf_wd;
	wire intr_state_rxf_we;
	wire intr_state_rxlvl_qs;
	wire intr_state_rxlvl_wd;
	wire intr_state_rxlvl_we;
	wire intr_state_txlvl_qs;
	wire intr_state_txlvl_wd;
	wire intr_state_txlvl_we;
	wire intr_state_rxerr_qs;
	wire intr_state_rxerr_wd;
	wire intr_state_rxerr_we;
	wire intr_state_rxoverflow_qs;
	wire intr_state_rxoverflow_wd;
	wire intr_state_rxoverflow_we;
	wire intr_state_txunderflow_qs;
	wire intr_state_txunderflow_wd;
	wire intr_state_txunderflow_we;
	wire intr_enable_rxf_qs;
	wire intr_enable_rxf_wd;
	wire intr_enable_rxf_we;
	wire intr_enable_rxlvl_qs;
	wire intr_enable_rxlvl_wd;
	wire intr_enable_rxlvl_we;
	wire intr_enable_txlvl_qs;
	wire intr_enable_txlvl_wd;
	wire intr_enable_txlvl_we;
	wire intr_enable_rxerr_qs;
	wire intr_enable_rxerr_wd;
	wire intr_enable_rxerr_we;
	wire intr_enable_rxoverflow_qs;
	wire intr_enable_rxoverflow_wd;
	wire intr_enable_rxoverflow_we;
	wire intr_enable_txunderflow_qs;
	wire intr_enable_txunderflow_wd;
	wire intr_enable_txunderflow_we;
	wire intr_test_rxf_wd;
	wire intr_test_rxf_we;
	wire intr_test_rxlvl_wd;
	wire intr_test_rxlvl_we;
	wire intr_test_txlvl_wd;
	wire intr_test_txlvl_we;
	wire intr_test_rxerr_wd;
	wire intr_test_rxerr_we;
	wire intr_test_rxoverflow_wd;
	wire intr_test_rxoverflow_we;
	wire intr_test_txunderflow_wd;
	wire intr_test_txunderflow_we;
	wire control_abort_qs;
	wire control_abort_wd;
	wire control_abort_we;
	wire [1:0] control_mode_qs;
	wire [1:0] control_mode_wd;
	wire control_mode_we;
	wire control_rst_txfifo_qs;
	wire control_rst_txfifo_wd;
	wire control_rst_txfifo_we;
	wire control_rst_rxfifo_qs;
	wire control_rst_rxfifo_wd;
	wire control_rst_rxfifo_we;
	wire cfg_cpol_qs;
	wire cfg_cpol_wd;
	wire cfg_cpol_we;
	wire cfg_cpha_qs;
	wire cfg_cpha_wd;
	wire cfg_cpha_we;
	wire cfg_tx_order_qs;
	wire cfg_tx_order_wd;
	wire cfg_tx_order_we;
	wire cfg_rx_order_qs;
	wire cfg_rx_order_wd;
	wire cfg_rx_order_we;
	wire [7:0] cfg_timer_v_qs;
	wire [7:0] cfg_timer_v_wd;
	wire cfg_timer_v_we;
	wire [15:0] fifo_level_rxlvl_qs;
	wire [15:0] fifo_level_rxlvl_wd;
	wire fifo_level_rxlvl_we;
	wire [15:0] fifo_level_txlvl_qs;
	wire [15:0] fifo_level_txlvl_wd;
	wire fifo_level_txlvl_we;
	wire [7:0] async_fifo_level_rxlvl_qs;
	wire async_fifo_level_rxlvl_re;
	wire [7:0] async_fifo_level_txlvl_qs;
	wire async_fifo_level_txlvl_re;
	wire status_rxf_full_qs;
	wire status_rxf_full_re;
	wire status_rxf_empty_qs;
	wire status_rxf_empty_re;
	wire status_txf_full_qs;
	wire status_txf_full_re;
	wire status_txf_empty_qs;
	wire status_txf_empty_re;
	wire status_abort_done_qs;
	wire status_abort_done_re;
	wire status_csb_qs;
	wire status_csb_re;
	wire [15:0] rxf_ptr_rptr_qs;
	wire [15:0] rxf_ptr_rptr_wd;
	wire rxf_ptr_rptr_we;
	wire [15:0] rxf_ptr_wptr_qs;
	wire [15:0] txf_ptr_rptr_qs;
	wire [15:0] txf_ptr_wptr_qs;
	wire [15:0] txf_ptr_wptr_wd;
	wire txf_ptr_wptr_we;
	wire [15:0] rxf_addr_base_qs;
	wire [15:0] rxf_addr_base_wd;
	wire rxf_addr_base_we;
	wire [15:0] rxf_addr_limit_qs;
	wire [15:0] rxf_addr_limit_wd;
	wire rxf_addr_limit_we;
	wire [15:0] txf_addr_base_qs;
	wire [15:0] txf_addr_base_wd;
	wire txf_addr_base_we;
	wire [15:0] txf_addr_limit_qs;
	wire [15:0] txf_addr_limit_wd;
	wire txf_addr_limit_we;
	prim_subreg #(
		.DW(1),
		.SWACCESS("W1C"),
		.RESVAL(1'h0)
	) u_intr_state_rxf(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(intr_state_rxf_we),
		.wd(intr_state_rxf_wd),
		.de(hw2reg[66]),
		.d(hw2reg[67]),
		.qe(),
		.q(reg2hw[168]),
		.qs(intr_state_rxf_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("W1C"),
		.RESVAL(1'h0)
	) u_intr_state_rxlvl(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(intr_state_rxlvl_we),
		.wd(intr_state_rxlvl_wd),
		.de(hw2reg[64]),
		.d(hw2reg[65]),
		.qe(),
		.q(reg2hw[167]),
		.qs(intr_state_rxlvl_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("W1C"),
		.RESVAL(1'h0)
	) u_intr_state_txlvl(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(intr_state_txlvl_we),
		.wd(intr_state_txlvl_wd),
		.de(hw2reg[62]),
		.d(hw2reg[63]),
		.qe(),
		.q(reg2hw[166]),
		.qs(intr_state_txlvl_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("W1C"),
		.RESVAL(1'h0)
	) u_intr_state_rxerr(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(intr_state_rxerr_we),
		.wd(intr_state_rxerr_wd),
		.de(hw2reg[60]),
		.d(hw2reg[61]),
		.qe(),
		.q(reg2hw[165]),
		.qs(intr_state_rxerr_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("W1C"),
		.RESVAL(1'h0)
	) u_intr_state_rxoverflow(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(intr_state_rxoverflow_we),
		.wd(intr_state_rxoverflow_wd),
		.de(hw2reg[58]),
		.d(hw2reg[59]),
		.qe(),
		.q(reg2hw[164]),
		.qs(intr_state_rxoverflow_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("W1C"),
		.RESVAL(1'h0)
	) u_intr_state_txunderflow(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(intr_state_txunderflow_we),
		.wd(intr_state_txunderflow_wd),
		.de(hw2reg[56]),
		.d(hw2reg[57]),
		.qe(),
		.q(reg2hw[163]),
		.qs(intr_state_txunderflow_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_intr_enable_rxf(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(intr_enable_rxf_we),
		.wd(intr_enable_rxf_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[162]),
		.qs(intr_enable_rxf_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_intr_enable_rxlvl(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(intr_enable_rxlvl_we),
		.wd(intr_enable_rxlvl_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[161]),
		.qs(intr_enable_rxlvl_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_intr_enable_txlvl(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(intr_enable_txlvl_we),
		.wd(intr_enable_txlvl_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[160]),
		.qs(intr_enable_txlvl_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_intr_enable_rxerr(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(intr_enable_rxerr_we),
		.wd(intr_enable_rxerr_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[159]),
		.qs(intr_enable_rxerr_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_intr_enable_rxoverflow(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(intr_enable_rxoverflow_we),
		.wd(intr_enable_rxoverflow_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[158]),
		.qs(intr_enable_rxoverflow_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_intr_enable_txunderflow(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(intr_enable_txunderflow_we),
		.wd(intr_enable_txunderflow_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[157]),
		.qs(intr_enable_txunderflow_qs)
	);
	prim_subreg_ext #(.DW(1)) u_intr_test_rxf(
		.re(1'b0),
		.we(intr_test_rxf_we),
		.wd(intr_test_rxf_wd),
		.d(1'sb0),
		.qre(),
		.qe(reg2hw[155]),
		.q(reg2hw[156]),
		.qs()
	);
	prim_subreg_ext #(.DW(1)) u_intr_test_rxlvl(
		.re(1'b0),
		.we(intr_test_rxlvl_we),
		.wd(intr_test_rxlvl_wd),
		.d(1'sb0),
		.qre(),
		.qe(reg2hw[153]),
		.q(reg2hw[154]),
		.qs()
	);
	prim_subreg_ext #(.DW(1)) u_intr_test_txlvl(
		.re(1'b0),
		.we(intr_test_txlvl_we),
		.wd(intr_test_txlvl_wd),
		.d(1'sb0),
		.qre(),
		.qe(reg2hw[151]),
		.q(reg2hw[152]),
		.qs()
	);
	prim_subreg_ext #(.DW(1)) u_intr_test_rxerr(
		.re(1'b0),
		.we(intr_test_rxerr_we),
		.wd(intr_test_rxerr_wd),
		.d(1'sb0),
		.qre(),
		.qe(reg2hw[149]),
		.q(reg2hw[150]),
		.qs()
	);
	prim_subreg_ext #(.DW(1)) u_intr_test_rxoverflow(
		.re(1'b0),
		.we(intr_test_rxoverflow_we),
		.wd(intr_test_rxoverflow_wd),
		.d(1'sb0),
		.qre(),
		.qe(reg2hw[147]),
		.q(reg2hw[148]),
		.qs()
	);
	prim_subreg_ext #(.DW(1)) u_intr_test_txunderflow(
		.re(1'b0),
		.we(intr_test_txunderflow_we),
		.wd(intr_test_txunderflow_wd),
		.d(1'sb0),
		.qre(),
		.qe(reg2hw[145]),
		.q(reg2hw[146]),
		.qs()
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_control_abort(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(control_abort_we),
		.wd(control_abort_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[144]),
		.qs(control_abort_qs)
	);
	prim_subreg #(
		.DW(2),
		.SWACCESS("RW"),
		.RESVAL(2'h0)
	) u_control_mode(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(control_mode_we),
		.wd(control_mode_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[143-:2]),
		.qs(control_mode_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_control_rst_txfifo(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(control_rst_txfifo_we),
		.wd(control_rst_txfifo_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[141]),
		.qs(control_rst_txfifo_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_control_rst_rxfifo(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(control_rst_rxfifo_we),
		.wd(control_rst_rxfifo_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[140]),
		.qs(control_rst_rxfifo_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_cfg_cpol(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(cfg_cpol_we),
		.wd(cfg_cpol_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[139]),
		.qs(cfg_cpol_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_cfg_cpha(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(cfg_cpha_we),
		.wd(cfg_cpha_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[138]),
		.qs(cfg_cpha_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_cfg_tx_order(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(cfg_tx_order_we),
		.wd(cfg_tx_order_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[137]),
		.qs(cfg_tx_order_qs)
	);
	prim_subreg #(
		.DW(1),
		.SWACCESS("RW"),
		.RESVAL(1'h0)
	) u_cfg_rx_order(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(cfg_rx_order_we),
		.wd(cfg_rx_order_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[136]),
		.qs(cfg_rx_order_qs)
	);
	prim_subreg #(
		.DW(8),
		.SWACCESS("RW"),
		.RESVAL(8'h7f)
	) u_cfg_timer_v(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(cfg_timer_v_we),
		.wd(cfg_timer_v_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[135-:8]),
		.qs(cfg_timer_v_qs)
	);
	prim_subreg #(
		.DW(16),
		.SWACCESS("RW"),
		.RESVAL(16'h80)
	) u_fifo_level_rxlvl(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(fifo_level_rxlvl_we),
		.wd(fifo_level_rxlvl_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[127-:16]),
		.qs(fifo_level_rxlvl_qs)
	);
	prim_subreg #(
		.DW(16),
		.SWACCESS("RW"),
		.RESVAL(16'h0)
	) u_fifo_level_txlvl(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(fifo_level_txlvl_we),
		.wd(fifo_level_txlvl_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[111-:16]),
		.qs(fifo_level_txlvl_qs)
	);
	prim_subreg_ext #(.DW(8)) u_async_fifo_level_rxlvl(
		.re(async_fifo_level_rxlvl_re),
		.we(1'b0),
		.wd(1'sb0),
		.d(hw2reg[55-:8]),
		.qre(),
		.qe(),
		.q(),
		.qs(async_fifo_level_rxlvl_qs)
	);
	prim_subreg_ext #(.DW(8)) u_async_fifo_level_txlvl(
		.re(async_fifo_level_txlvl_re),
		.we(1'b0),
		.wd(1'sb0),
		.d(hw2reg[47-:8]),
		.qre(),
		.qe(),
		.q(),
		.qs(async_fifo_level_txlvl_qs)
	);
	prim_subreg_ext #(.DW(1)) u_status_rxf_full(
		.re(status_rxf_full_re),
		.we(1'b0),
		.wd(1'sb0),
		.d(hw2reg[39]),
		.qre(),
		.qe(),
		.q(),
		.qs(status_rxf_full_qs)
	);
	prim_subreg_ext #(.DW(1)) u_status_rxf_empty(
		.re(status_rxf_empty_re),
		.we(1'b0),
		.wd(1'sb0),
		.d(hw2reg[38]),
		.qre(),
		.qe(),
		.q(),
		.qs(status_rxf_empty_qs)
	);
	prim_subreg_ext #(.DW(1)) u_status_txf_full(
		.re(status_txf_full_re),
		.we(1'b0),
		.wd(1'sb0),
		.d(hw2reg[37]),
		.qre(),
		.qe(),
		.q(),
		.qs(status_txf_full_qs)
	);
	prim_subreg_ext #(.DW(1)) u_status_txf_empty(
		.re(status_txf_empty_re),
		.we(1'b0),
		.wd(1'sb0),
		.d(hw2reg[36]),
		.qre(),
		.qe(),
		.q(),
		.qs(status_txf_empty_qs)
	);
	prim_subreg_ext #(.DW(1)) u_status_abort_done(
		.re(status_abort_done_re),
		.we(1'b0),
		.wd(1'sb0),
		.d(hw2reg[35]),
		.qre(),
		.qe(),
		.q(),
		.qs(status_abort_done_qs)
	);
	prim_subreg_ext #(.DW(1)) u_status_csb(
		.re(status_csb_re),
		.we(1'b0),
		.wd(1'sb0),
		.d(hw2reg[34]),
		.qre(),
		.qe(),
		.q(),
		.qs(status_csb_qs)
	);
	prim_subreg #(
		.DW(16),
		.SWACCESS("RW"),
		.RESVAL(16'h0)
	) u_rxf_ptr_rptr(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(rxf_ptr_rptr_we),
		.wd(rxf_ptr_rptr_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[95-:16]),
		.qs(rxf_ptr_rptr_qs)
	);
	prim_subreg #(
		.DW(16),
		.SWACCESS("RO"),
		.RESVAL(16'h0)
	) u_rxf_ptr_wptr(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(1'b0),
		.wd(1'sb0),
		.de(hw2reg[17]),
		.d(hw2reg[33-:16]),
		.qe(),
		.q(),
		.qs(rxf_ptr_wptr_qs)
	);
	prim_subreg #(
		.DW(16),
		.SWACCESS("RO"),
		.RESVAL(16'h0)
	) u_txf_ptr_rptr(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(1'b0),
		.wd(1'sb0),
		.de(hw2reg[0]),
		.d(hw2reg[16-:16]),
		.qe(),
		.q(),
		.qs(txf_ptr_rptr_qs)
	);
	prim_subreg #(
		.DW(16),
		.SWACCESS("RW"),
		.RESVAL(16'h0)
	) u_txf_ptr_wptr(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(txf_ptr_wptr_we),
		.wd(txf_ptr_wptr_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[79-:16]),
		.qs(txf_ptr_wptr_qs)
	);
	prim_subreg #(
		.DW(16),
		.SWACCESS("RW"),
		.RESVAL(16'h0)
	) u_rxf_addr_base(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(rxf_addr_base_we),
		.wd(rxf_addr_base_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[63-:16]),
		.qs(rxf_addr_base_qs)
	);
	prim_subreg #(
		.DW(16),
		.SWACCESS("RW"),
		.RESVAL(16'h1fc)
	) u_rxf_addr_limit(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(rxf_addr_limit_we),
		.wd(rxf_addr_limit_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[47-:16]),
		.qs(rxf_addr_limit_qs)
	);
	prim_subreg #(
		.DW(16),
		.SWACCESS("RW"),
		.RESVAL(16'h200)
	) u_txf_addr_base(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(txf_addr_base_we),
		.wd(txf_addr_base_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[31-:16]),
		.qs(txf_addr_base_qs)
	);
	prim_subreg #(
		.DW(16),
		.SWACCESS("RW"),
		.RESVAL(16'h3fc)
	) u_txf_addr_limit(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.we(txf_addr_limit_we),
		.wd(txf_addr_limit_wd),
		.de(1'b0),
		.d(1'sb0),
		.qe(),
		.q(reg2hw[15-:16]),
		.qs(txf_addr_limit_qs)
	);
	reg [11:0] addr_hit;
	always @(*) begin
		addr_hit = 1'sb0;
		addr_hit[0] = reg_addr == SPI_DEVICE_INTR_STATE_OFFSET;
		addr_hit[1] = reg_addr == SPI_DEVICE_INTR_ENABLE_OFFSET;
		addr_hit[2] = reg_addr == SPI_DEVICE_INTR_TEST_OFFSET;
		addr_hit[3] = reg_addr == SPI_DEVICE_CONTROL_OFFSET;
		addr_hit[4] = reg_addr == SPI_DEVICE_CFG_OFFSET;
		addr_hit[5] = reg_addr == SPI_DEVICE_FIFO_LEVEL_OFFSET;
		addr_hit[6] = reg_addr == SPI_DEVICE_ASYNC_FIFO_LEVEL_OFFSET;
		addr_hit[7] = reg_addr == SPI_DEVICE_STATUS_OFFSET;
		addr_hit[8] = reg_addr == SPI_DEVICE_RXF_PTR_OFFSET;
		addr_hit[9] = reg_addr == SPI_DEVICE_TXF_PTR_OFFSET;
		addr_hit[10] = reg_addr == SPI_DEVICE_RXF_ADDR_OFFSET;
		addr_hit[11] = reg_addr == SPI_DEVICE_TXF_ADDR_OFFSET;
	end
	assign addrmiss = (reg_re || reg_we ? ~|addr_hit : 1'b0);
	always @(*) begin
		wr_err = 1'b0;
		if ((addr_hit[0] && reg_we) && (SPI_DEVICE_PERMIT[44+:4] != (SPI_DEVICE_PERMIT[44+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[1] && reg_we) && (SPI_DEVICE_PERMIT[40+:4] != (SPI_DEVICE_PERMIT[40+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[2] && reg_we) && (SPI_DEVICE_PERMIT[36+:4] != (SPI_DEVICE_PERMIT[36+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[3] && reg_we) && (SPI_DEVICE_PERMIT[32+:4] != (SPI_DEVICE_PERMIT[32+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[4] && reg_we) && (SPI_DEVICE_PERMIT[28+:4] != (SPI_DEVICE_PERMIT[28+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[5] && reg_we) && (SPI_DEVICE_PERMIT[24+:4] != (SPI_DEVICE_PERMIT[24+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[6] && reg_we) && (SPI_DEVICE_PERMIT[20+:4] != (SPI_DEVICE_PERMIT[20+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[7] && reg_we) && (SPI_DEVICE_PERMIT[16+:4] != (SPI_DEVICE_PERMIT[16+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[8] && reg_we) && (SPI_DEVICE_PERMIT[12+:4] != (SPI_DEVICE_PERMIT[12+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[9] && reg_we) && (SPI_DEVICE_PERMIT[8+:4] != (SPI_DEVICE_PERMIT[8+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[10] && reg_we) && (SPI_DEVICE_PERMIT[4+:4] != (SPI_DEVICE_PERMIT[4+:4] & reg_be)))
			wr_err = 1'b1;
		if ((addr_hit[11] && reg_we) && (SPI_DEVICE_PERMIT[0+:4] != (SPI_DEVICE_PERMIT[0+:4] & reg_be)))
			wr_err = 1'b1;
	end
	assign intr_state_rxf_we = (addr_hit[0] & reg_we) & ~wr_err;
	assign intr_state_rxf_wd = reg_wdata[0];
	assign intr_state_rxlvl_we = (addr_hit[0] & reg_we) & ~wr_err;
	assign intr_state_rxlvl_wd = reg_wdata[1];
	assign intr_state_txlvl_we = (addr_hit[0] & reg_we) & ~wr_err;
	assign intr_state_txlvl_wd = reg_wdata[2];
	assign intr_state_rxerr_we = (addr_hit[0] & reg_we) & ~wr_err;
	assign intr_state_rxerr_wd = reg_wdata[3];
	assign intr_state_rxoverflow_we = (addr_hit[0] & reg_we) & ~wr_err;
	assign intr_state_rxoverflow_wd = reg_wdata[4];
	assign intr_state_txunderflow_we = (addr_hit[0] & reg_we) & ~wr_err;
	assign intr_state_txunderflow_wd = reg_wdata[5];
	assign intr_enable_rxf_we = (addr_hit[1] & reg_we) & ~wr_err;
	assign intr_enable_rxf_wd = reg_wdata[0];
	assign intr_enable_rxlvl_we = (addr_hit[1] & reg_we) & ~wr_err;
	assign intr_enable_rxlvl_wd = reg_wdata[1];
	assign intr_enable_txlvl_we = (addr_hit[1] & reg_we) & ~wr_err;
	assign intr_enable_txlvl_wd = reg_wdata[2];
	assign intr_enable_rxerr_we = (addr_hit[1] & reg_we) & ~wr_err;
	assign intr_enable_rxerr_wd = reg_wdata[3];
	assign intr_enable_rxoverflow_we = (addr_hit[1] & reg_we) & ~wr_err;
	assign intr_enable_rxoverflow_wd = reg_wdata[4];
	assign intr_enable_txunderflow_we = (addr_hit[1] & reg_we) & ~wr_err;
	assign intr_enable_txunderflow_wd = reg_wdata[5];
	assign intr_test_rxf_we = (addr_hit[2] & reg_we) & ~wr_err;
	assign intr_test_rxf_wd = reg_wdata[0];
	assign intr_test_rxlvl_we = (addr_hit[2] & reg_we) & ~wr_err;
	assign intr_test_rxlvl_wd = reg_wdata[1];
	assign intr_test_txlvl_we = (addr_hit[2] & reg_we) & ~wr_err;
	assign intr_test_txlvl_wd = reg_wdata[2];
	assign intr_test_rxerr_we = (addr_hit[2] & reg_we) & ~wr_err;
	assign intr_test_rxerr_wd = reg_wdata[3];
	assign intr_test_rxoverflow_we = (addr_hit[2] & reg_we) & ~wr_err;
	assign intr_test_rxoverflow_wd = reg_wdata[4];
	assign intr_test_txunderflow_we = (addr_hit[2] & reg_we) & ~wr_err;
	assign intr_test_txunderflow_wd = reg_wdata[5];
	assign control_abort_we = (addr_hit[3] & reg_we) & ~wr_err;
	assign control_abort_wd = reg_wdata[0];
	assign control_mode_we = (addr_hit[3] & reg_we) & ~wr_err;
	assign control_mode_wd = reg_wdata[5:4];
	assign control_rst_txfifo_we = (addr_hit[3] & reg_we) & ~wr_err;
	assign control_rst_txfifo_wd = reg_wdata[16];
	assign control_rst_rxfifo_we = (addr_hit[3] & reg_we) & ~wr_err;
	assign control_rst_rxfifo_wd = reg_wdata[17];
	assign cfg_cpol_we = (addr_hit[4] & reg_we) & ~wr_err;
	assign cfg_cpol_wd = reg_wdata[0];
	assign cfg_cpha_we = (addr_hit[4] & reg_we) & ~wr_err;
	assign cfg_cpha_wd = reg_wdata[1];
	assign cfg_tx_order_we = (addr_hit[4] & reg_we) & ~wr_err;
	assign cfg_tx_order_wd = reg_wdata[2];
	assign cfg_rx_order_we = (addr_hit[4] & reg_we) & ~wr_err;
	assign cfg_rx_order_wd = reg_wdata[3];
	assign cfg_timer_v_we = (addr_hit[4] & reg_we) & ~wr_err;
	assign cfg_timer_v_wd = reg_wdata[15:8];
	assign fifo_level_rxlvl_we = (addr_hit[5] & reg_we) & ~wr_err;
	assign fifo_level_rxlvl_wd = reg_wdata[15:0];
	assign fifo_level_txlvl_we = (addr_hit[5] & reg_we) & ~wr_err;
	assign fifo_level_txlvl_wd = reg_wdata[31:16];
	assign async_fifo_level_rxlvl_re = addr_hit[6] && reg_re;
	assign async_fifo_level_txlvl_re = addr_hit[6] && reg_re;
	assign status_rxf_full_re = addr_hit[7] && reg_re;
	assign status_rxf_empty_re = addr_hit[7] && reg_re;
	assign status_txf_full_re = addr_hit[7] && reg_re;
	assign status_txf_empty_re = addr_hit[7] && reg_re;
	assign status_abort_done_re = addr_hit[7] && reg_re;
	assign status_csb_re = addr_hit[7] && reg_re;
	assign rxf_ptr_rptr_we = (addr_hit[8] & reg_we) & ~wr_err;
	assign rxf_ptr_rptr_wd = reg_wdata[15:0];
	assign txf_ptr_wptr_we = (addr_hit[9] & reg_we) & ~wr_err;
	assign txf_ptr_wptr_wd = reg_wdata[31:16];
	assign rxf_addr_base_we = (addr_hit[10] & reg_we) & ~wr_err;
	assign rxf_addr_base_wd = reg_wdata[15:0];
	assign rxf_addr_limit_we = (addr_hit[10] & reg_we) & ~wr_err;
	assign rxf_addr_limit_wd = reg_wdata[31:16];
	assign txf_addr_base_we = (addr_hit[11] & reg_we) & ~wr_err;
	assign txf_addr_base_wd = reg_wdata[15:0];
	assign txf_addr_limit_we = (addr_hit[11] & reg_we) & ~wr_err;
	assign txf_addr_limit_wd = reg_wdata[31:16];
	always @(*) begin
		reg_rdata_next = 1'sb0;
		case (1'b1)
			addr_hit[0]: begin
				reg_rdata_next[0] = intr_state_rxf_qs;
				reg_rdata_next[1] = intr_state_rxlvl_qs;
				reg_rdata_next[2] = intr_state_txlvl_qs;
				reg_rdata_next[3] = intr_state_rxerr_qs;
				reg_rdata_next[4] = intr_state_rxoverflow_qs;
				reg_rdata_next[5] = intr_state_txunderflow_qs;
			end
			addr_hit[1]: begin
				reg_rdata_next[0] = intr_enable_rxf_qs;
				reg_rdata_next[1] = intr_enable_rxlvl_qs;
				reg_rdata_next[2] = intr_enable_txlvl_qs;
				reg_rdata_next[3] = intr_enable_rxerr_qs;
				reg_rdata_next[4] = intr_enable_rxoverflow_qs;
				reg_rdata_next[5] = intr_enable_txunderflow_qs;
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
				reg_rdata_next[0] = control_abort_qs;
				reg_rdata_next[5:4] = control_mode_qs;
				reg_rdata_next[16] = control_rst_txfifo_qs;
				reg_rdata_next[17] = control_rst_rxfifo_qs;
			end
			addr_hit[4]: begin
				reg_rdata_next[0] = cfg_cpol_qs;
				reg_rdata_next[1] = cfg_cpha_qs;
				reg_rdata_next[2] = cfg_tx_order_qs;
				reg_rdata_next[3] = cfg_rx_order_qs;
				reg_rdata_next[15:8] = cfg_timer_v_qs;
			end
			addr_hit[5]: begin
				reg_rdata_next[15:0] = fifo_level_rxlvl_qs;
				reg_rdata_next[31:16] = fifo_level_txlvl_qs;
			end
			addr_hit[6]: begin
				reg_rdata_next[7:0] = async_fifo_level_rxlvl_qs;
				reg_rdata_next[23:16] = async_fifo_level_txlvl_qs;
			end
			addr_hit[7]: begin
				reg_rdata_next[0] = status_rxf_full_qs;
				reg_rdata_next[1] = status_rxf_empty_qs;
				reg_rdata_next[2] = status_txf_full_qs;
				reg_rdata_next[3] = status_txf_empty_qs;
				reg_rdata_next[4] = status_abort_done_qs;
				reg_rdata_next[5] = status_csb_qs;
			end
			addr_hit[8]: begin
				reg_rdata_next[15:0] = rxf_ptr_rptr_qs;
				reg_rdata_next[31:16] = rxf_ptr_wptr_qs;
			end
			addr_hit[9]: begin
				reg_rdata_next[15:0] = txf_ptr_rptr_qs;
				reg_rdata_next[31:16] = txf_ptr_wptr_qs;
			end
			addr_hit[10]: begin
				reg_rdata_next[15:0] = rxf_addr_base_qs;
				reg_rdata_next[31:16] = rxf_addr_limit_qs;
			end
			addr_hit[11]: begin
				reg_rdata_next[15:0] = txf_addr_base_qs;
				reg_rdata_next[31:16] = txf_addr_limit_qs;
			end
			default: reg_rdata_next = 1'sb1;
		endcase
	end
endmodule
