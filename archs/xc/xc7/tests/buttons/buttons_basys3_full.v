module top(
    input  wire clk,

	input  wire [15:0] sw,
	output wire [15:0] led,

    input  wire rx,
    output wire tx
);

assign led = sw;

endmodule
