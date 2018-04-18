module top (
	input  clk,
	output o
);
	reg [2:0] counter = 0;
	always @(posedge clk)
		counter <= counter + 1;
	assign o = counter[2];
endmodule
