module adder(
	input a,
	input b,
	input ci,
	(* DELAY_CONST_a = "20e-12" *)
	(* DELAY_CONST_b = "20e-12" *)
	(* DELAY_CONST_ci = "10e-12" *)
	output y,
	(* DELAY_CONST_a = "10e-12" *)
	(* DELAY_CONST_b = "10e-12" *)
	(* DELAY_CONST_ci = "7e-12" *)
	output co);
assign {co, y} = a + b + ci;
endmodule
