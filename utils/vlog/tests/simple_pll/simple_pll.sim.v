/* Simple model of a PLL which divides the input block by 64 */
module simple_pll (in_clock, out_clock);

	input wire in_clock;

	(* CLOCK *)
	output wire out_clock;

	reg [63:0] counter;
	always @(posedge in_clock) begin
		counter = counter + 1;
	end

	assign out_clock = counter[63];
endmodule
