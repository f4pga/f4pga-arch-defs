module top(
	input [15:0] in,
	output [15:0] out
);
  assign out = in + 16'h5A69;
endmodule
