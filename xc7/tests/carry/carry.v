module top(
    input  wire clk,

    input  wire rx,
    output wire tx,

	input  wire [15:0] sw,
	output wire [15:0] led
);
  assign led = sw;

  // Uart loopback
  assign tx = rx;
endmodule
