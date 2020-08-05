module top (
	input  wire clk,

	input  wire [3:0] sw,
	output wire [3:0] led
);
	wire clk_bufg;
	BUFG bufgctrl(.I(clk), .O(clk_bufg));

	localparam BITS = 4;
	localparam LOG2DELAY = 25;

	reg [BITS+LOG2DELAY-1:0] counter = 0;

	always @(posedge clk_bufg) begin
		counter <= counter + 1;
	end

	assign led = (counter >> LOG2DELAY) | sw;
endmodule
