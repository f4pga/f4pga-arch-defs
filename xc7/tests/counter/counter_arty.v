module top (
    input  wire clk,

    input  wire rx,
    output wire tx,

    input  wire [7:0] sw,
    output wire [7:0] led
);

    localparam BITS = 1;
    localparam LOG2DELAY = 25;

    reg [BITS+LOG2DELAY-1:0] counter = 0;

    always @(posedge clk) begin
    	counter <= counter + 1;
    end

    assign led[7] = counter >> LOG2DELAY;
endmodule
