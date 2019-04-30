/*
 * `output wire clk` should be detected as a clock despite this being a black
 * box module.
 */
(* blackbox *)
module block(a, b, clk);
	input wire a;
	input wire b;
	output wire clk;
endmodule
