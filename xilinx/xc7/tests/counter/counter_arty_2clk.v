module top (
    input  wire clk1,
    input  wire clk2,
    input  wire [7:0] sw,
    output wire [7:0] led
);

    localparam BITS = 4;
    localparam LOG2DELAY = 26;

    reg [BITS+LOG2DELAY-1:0] counter1 = 0;
    reg [BITS+LOG2DELAY-1:0] counter2 = 0;

    always @(posedge clk2) begin
    	counter1 <= counter1 + 1;
    end

    always @(posedge clk1) begin
    	counter2 <= counter2 + 1;
    end

    assign led[3:0] = counter1 >> LOG2DELAY;
    assign led[7:4] = counter2 >> LOG2DELAY;
endmodule
