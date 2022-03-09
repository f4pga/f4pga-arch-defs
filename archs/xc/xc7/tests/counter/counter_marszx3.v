module top (
	input  wire clk,

	output wire [3:0] led
);

	localparam BITS = 8;
	localparam LOG2DELAY = 18;

	reg [BITS+LOG2DELAY-1:0] counter = 0;

	always @(posedge clk) begin
		counter <= counter + 1;
	end

	assign led = counter >> LOG2DELAY;
endmodule
