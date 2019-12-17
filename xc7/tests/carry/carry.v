module top(
    input  wire clk,

    input  wire rx,
    output wire tx,

	input [15:0] sw,
	output [15:0] led
);
  assign led = sw;

  // Uart loopback
  assign tx = rx;
endmodule
