(*blackbox*) (* MODEL_NAME="XORCY" *)
module CARRY4_{W}XOR(O, CI, LI);
	(* DELAY_CONST_CI="10e-12" *)
	(* DELAY_CONST_LI="10e-12" *)
	output wire O;

	input wire CI;
	input wire LI;

	assign O = CI ^ LI;
endmodule
