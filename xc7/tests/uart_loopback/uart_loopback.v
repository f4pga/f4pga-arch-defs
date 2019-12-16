module top (
	input  wire clk,

	input  wire rx,
	output wire tx,

	input  wire rst,
	output wire led
);

	assign tx = rx;

endmodule
