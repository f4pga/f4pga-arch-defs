module XORCY(O, CI, LI);
	output wire O;
	input wire CI;
	input wire LI;

	assign O = CI ^ LI;
endmodule
