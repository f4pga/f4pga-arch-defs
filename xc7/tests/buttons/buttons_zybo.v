module top(
    input  wire clk,

    input  wire [2:0] sw,
    output wire [3:0] led
);
    assign led[2:0] = sw;
endmodule
