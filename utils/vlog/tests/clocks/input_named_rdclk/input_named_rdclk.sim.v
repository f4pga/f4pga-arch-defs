/*
 * `input wire rdclk` should be detected as a clock despite this being a black
 * box module.
 */
(* blackbox *)
module block(rdclk, a, o);
	input wire rdclk;
	input wire a;
	output wire o;
endmodule
