module top(
    input  wire clk,

    input  wire rx,
    output wire tx,

    input  wire [15:0] sw,
    output wire [15:0] led
);
    localparam LOG2DELAY = 22;

    reg [LOG2DELAY-1:0] counter0 = 0;
    reg [LOG2DELAY-1:0] counter1 = 0;
    reg [LOG2DELAY-1:0] counter2 = 0;
    reg [LOG2DELAY-1:0] counter3 = 0;
    reg [LOG2DELAY-1:0] counter4 = 0;
    reg [LOG2DELAY-1:0] counter5 = 0;
    reg [LOG2DELAY-1:0] counter6 = 0;
    reg [LOG2DELAY-1:0] counter7 = 0;

    always @(posedge clk) begin
    	counter0 <= counter0 + 1;
    	counter1 <= counter1 + 1;
    	counter2 <= counter2 + 1;
    	counter3 <= counter3 + 1;
    	counter4 <= counter4 + 1;
    	counter5 <= counter5 + 1;
    	counter6 <= counter6 + 1;
    	counter7 <= counter7 + 1;
    end

    assign led[0] = counter0[LOG2DELAY-1];
    assign led[1] = counter1[LOG2DELAY-1];
    assign led[2] = counter2[LOG2DELAY-1];
    assign led[3] = counter3[LOG2DELAY-1];
    assign led[4] = counter4[LOG2DELAY-1];
    assign led[5] = counter5[LOG2DELAY-1];
    assign led[6] = counter6[LOG2DELAY-1];
    assign led[7] = counter7[LOG2DELAY-1];
endmodule
