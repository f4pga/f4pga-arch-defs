/*
 * `output wire o` should be detected as a clock because of the `(* CLOCK *)`
 * attribute.
 */
(* blackbox *)
module block(a, b, o);
	input wire a;
	input wire b;
	(* CLOCK *)
	output wire o;
endmodule
