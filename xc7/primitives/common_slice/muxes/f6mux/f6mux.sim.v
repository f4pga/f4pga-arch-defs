(* blackbox *) (* MODEL_NAME="MUXF6" *)
module F6MUX(I0, I1, S, O);

	input wire I0;
	input wire I1;
	input wire S;
	(* DELAY_CONST_I0 = "1e-11"/*"{{iopath_A1_6}}"*/ *)
	(* DELAY_CONST_I1 = "1e-11"/*"{{iopath_A1_6}}"*/ *)
	(* DELAY_CONST_S = "1e-11"/*"{{iopath_A1_6}}"*/ *)
	output wire O;

	assign O = S ? I1 : I0;

endmodule
