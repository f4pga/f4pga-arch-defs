module dff(input clk, rst, d, output q);

always @(posedge clk)
	if (rst == 1'b1)
		q <= 1'b0;
	else
		q <= d;

endmodule
