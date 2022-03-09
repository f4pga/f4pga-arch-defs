module top (
	input  wire clk,

	input  wire rx,
	output wire tx,

	input  wire rst,
	input  wire led  // unused
);

	assign tx = rx;

endmodule
