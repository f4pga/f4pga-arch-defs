module top (
	input  clk,
	output LD7,
);

	localparam BITS = 1;
	localparam LOG2DELAY = 25;

	reg [BITS+LOG2DELAY-1:0] counter = 0;

	always @(posedge clk) begin
		counter <= counter + 1;
	end

	assign {LD7} = counter >> LOG2DELAY;
endmodule
