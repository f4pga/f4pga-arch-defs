module top (
	output UART_TX,
	input  UART_RX
);

	assign UART_TX = UART_RX;

endmodule
