module uart (
	clk_i,
	rst_ni,
	tl_i,
	tl_o,
	cio_rx_i,
	cio_tx_o,
	cio_tx_en_o,
	intr_tx_watermark_o,
	intr_rx_watermark_o,
	intr_tx_empty_o,
	intr_rx_overflow_o,
	intr_rx_frame_err_o,
	intr_rx_break_err_o,
	intr_rx_timeout_o,
	intr_rx_parity_err_o
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
	input cio_rx_i;
	output wire cio_tx_o;
	output wire cio_tx_en_o;
	output wire intr_tx_watermark_o;
	output wire intr_rx_watermark_o;
	output wire intr_tx_empty_o;
	output wire intr_rx_overflow_o;
	output wire intr_rx_frame_err_o;
	output wire intr_rx_break_err_o;
	output wire intr_rx_timeout_o;
	output wire intr_rx_parity_err_o;
	parameter [5:0] UART_INTR_STATE_OFFSET = 6'h 0;
	parameter [5:0] UART_INTR_ENABLE_OFFSET = 6'h 4;
	parameter [5:0] UART_INTR_TEST_OFFSET = 6'h 8;
	parameter [5:0] UART_CTRL_OFFSET = 6'h c;
	parameter [5:0] UART_STATUS_OFFSET = 6'h 10;
	parameter [5:0] UART_RDATA_OFFSET = 6'h 14;
	parameter [5:0] UART_WDATA_OFFSET = 6'h 18;
	parameter [5:0] UART_FIFO_CTRL_OFFSET = 6'h 1c;
	parameter [5:0] UART_FIFO_STATUS_OFFSET = 6'h 20;
	parameter [5:0] UART_OVRD_OFFSET = 6'h 24;
	parameter [5:0] UART_VAL_OFFSET = 6'h 28;
	parameter [5:0] UART_TIMEOUT_CTRL_OFFSET = 6'h 2c;
	parameter [47:0] UART_PERMIT = {4'b 0001, 4'b 0001, 4'b 0001, 4'b 1111, 4'b 0001, 4'b 0001, 4'b 0001, 4'b 0001, 4'b 0111, 4'b 0001, 4'b 0011, 4'b 1111};
	localparam UART_INTR_STATE = 0;
	localparam UART_INTR_ENABLE = 1;
	localparam UART_VAL = 10;
	localparam UART_TIMEOUT_CTRL = 11;
	localparam UART_INTR_TEST = 2;
	localparam UART_CTRL = 3;
	localparam UART_STATUS = 4;
	localparam UART_RDATA = 5;
	localparam UART_WDATA = 6;
	localparam UART_FIFO_CTRL = 7;
	localparam UART_FIFO_STATUS = 8;
	localparam UART_OVRD = 9;
	wire [124:0] reg2hw;
	wire [64:0] hw2reg;
	uart_reg_top u_reg(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.tl_i(tl_i),
		.tl_o(tl_o),
		.reg2hw(reg2hw),
		.hw2reg(hw2reg),
		.devmode_i(1'b1)
	);
	uart_core uart_core(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.reg2hw(reg2hw),
		.hw2reg(hw2reg),
		.rx(cio_rx_i),
		.tx(cio_tx_o),
		.intr_tx_watermark_o(intr_tx_watermark_o),
		.intr_rx_watermark_o(intr_rx_watermark_o),
		.intr_tx_empty_o(intr_tx_empty_o),
		.intr_rx_overflow_o(intr_rx_overflow_o),
		.intr_rx_frame_err_o(intr_rx_frame_err_o),
		.intr_rx_break_err_o(intr_rx_break_err_o),
		.intr_rx_timeout_o(intr_rx_timeout_o),
		.intr_rx_parity_err_o(intr_rx_parity_err_o)
	);
	assign cio_tx_en_o = 1'b1;
endmodule
