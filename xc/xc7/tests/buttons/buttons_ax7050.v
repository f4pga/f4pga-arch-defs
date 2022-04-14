`timescale 1ns/1ps
module top (

    input  wire [1:0] sw,
    output wire [1:0] led,
);
    assign led = sw;
endmodule
