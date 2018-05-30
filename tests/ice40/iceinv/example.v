/* Binary counter displayed on LEDs (the 4 green ones on the right).
 * Changes value about once a second.
 */
module top (
	input  clk,
	input  btn,
	output LED3,
	output LED4,
	output LED5
);

	assign LED3 = btn;
	assign LED4 = clk;
	assign LED5 = 1'bX;
endmodule
