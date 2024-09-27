(* whitebox *)  (* CLASS="lut" *)
module LUT (in, out);
	parameter [15:0] INIT = 16'hDEAD;

	(* PORT_CLASS = "lut_in" *)
	input [3:0] in;

	(* PORT_CLASS = "lut_out" *)
	(* DELAY_MATRIX_in = "10e-12; 10e-12; 10e-12; 10e-12" *)
	output out;

	assign out = INIT[in];
endmodule
