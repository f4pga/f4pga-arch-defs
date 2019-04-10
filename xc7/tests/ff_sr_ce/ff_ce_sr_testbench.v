`timescale 1ns/1ps
`default_nettype none
module test;

localparam NUM_FF = 4;

`include "../../../library/tbassert.v"

reg clk = 0;
reg rx = 1;
reg [15:0] sw = 0;

wire tx;
wire [15:0] led;


// clock generation
always #1 clk=~clk;

always #1 $monitor("%d %d %d %d %d", $time, clk, sw[14], led[0], led[1], led[2], led[3]);

top unt(
    .clk(clk),
    .rx(rx),
    .tx(tx),
    .sw(sw),
    .led(led)
);

initial begin
#1.1
    tbassert(clk, "Clock!");
#1
    tbassert(!clk, "Clock!");
#1  $finish;
end

endmodule
