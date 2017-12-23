module CARRY4_{W}XOR(O, CI, LI);
	output wire O;
	input wire CI;
	input wire LI;

	assign O = CI ^ LI;
endmodule
