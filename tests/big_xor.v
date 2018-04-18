module top (
	input [6:0] in,
	output out 
);
	assign out = ^in;
endmodule
