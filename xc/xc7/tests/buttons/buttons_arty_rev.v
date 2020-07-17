module top (
    input  wire clk,

    input  wire [7:0] sw,
    output wire [0:7] led,
);
    assign led = sw;
endmodule
