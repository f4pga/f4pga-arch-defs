/*
 * `output wire rdclk` and `output wire wrclk` should be detected as a clock
 * despite this being a black box module.
 */
(* whitebox *)
module BLOCK(a, b, rdclk, o, wrclk);
	input wire a;
	input wire b;
	output wire rdclk;
	output wire o;
	output wire wrclk;
endmodule
