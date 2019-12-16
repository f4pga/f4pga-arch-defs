module top (
	input  wire clk,

    input  wire rx,
	output wire tx,

	input  wire [7:0] sw,
	output wire [7:0] led
);
  assign led = sw;
endmodule
