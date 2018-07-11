module top (
	input  clk,
	input  [3:0] i,
	output reg o
);
	always @(posedge clk)
		o <= ^i;
endmodule
