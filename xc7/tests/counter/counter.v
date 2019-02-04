module top (
	input  clk,
	output LED1,
	output LED2,
	output LED3,
	output LED4
);

	localparam BITS = 4;
	localparam LOG2DELAY = 22;

	reg [BITS+LOG2DELAY-1:0] counter = 0;

	always @(posedge clk) begin
		counter <= counter + 1;
	end

	assign {LED1, LED2, LED3, LED4} = counter >> LOG2DELAY;
endmodule
