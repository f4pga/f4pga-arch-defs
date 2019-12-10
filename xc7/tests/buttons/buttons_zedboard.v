module top(
    input  wire clk,

	input  wire sw,
	output wire led
);
  assign led = sw;
endmodule
