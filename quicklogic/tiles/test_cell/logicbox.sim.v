(* whitebox *)
module LOGICBOX (I, O);
	input wire I;

	// we need this delay to make VPR see
	// the connection between I and O
	(* DELAY_CONST_I="30e-12" *)
	output wire O;

	assign O=I;
endmodule
