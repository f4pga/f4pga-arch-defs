/*
 * `output wire clk` should be detected as a clock despite this being a black
 * box module.
 */
(* whitebox *)
module BLOCK(a, b, clk);
	input wire a;
	input wire b;
	output wire clk;
endmodule
