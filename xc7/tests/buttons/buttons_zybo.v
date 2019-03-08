module top(
	input [2:0] in,
	output [3:0] out
);
  assign out = { in[2], in };
endmodule
