/* Binary counter displayed on LEDs (the 4 green ones on the right).
 * Changes value about once a second.
 */

`ifndef CLK_MHZ
`define CLK_MHZ 12.5
// CLK_MHZ 4 -> LOG2DELAY 22
`endif

module top (
	input  clk,
	output LED2,
	output LED3,
	output LED4,
	output LED5
);

	localparam BITS = 4;
	// CLK_MHZ * 1e6 / 100
	localparam LOG2DELAY = $clog2(`CLK_MHZ * 1e6 / 100);

	reg [BITS+LOG2DELAY-1:0] counter = 0;
	reg [BITS-1:0] outcnt;

	always @(posedge clk) begin
		counter <= counter + 1;
		outcnt <= counter >> LOG2DELAY;
	end

	assign {LED2, LED3, LED4, LED5} = outcnt;
endmodule
