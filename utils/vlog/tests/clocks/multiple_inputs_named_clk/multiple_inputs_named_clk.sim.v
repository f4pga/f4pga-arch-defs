/*
 * `input wire rdclk` and `input wire wrclk` should be detected as a clock
 * despite this being a black box module.
 */
(* whitebox *)
module BLOCK(a, rdclk, b, wrclk, c, o);
	input wire a;
	input wire rdclk;
	input wire b;
	input wire wrclk;
	input wire c;
	output wire o;
endmodule
