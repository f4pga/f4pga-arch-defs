module top (
	input  wire clk,

	input  wire [2:0] sw,
	output wire [1:0] led
);

	localparam BITS = 2;
	localparam LOG2DELAY = 22;

	reg [BITS+LOG2DELAY-1:0] counter = 0;

	always @(posedge clk) begin
		counter <= counter + 1;
	end

	assign led = counter >> LOG2DELAY;
endmodule
