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

always #1 $monitor("%d %d %d %d %d %d %d", $time, clk, sw[14], led[0], led[1], led[2], led[3]);

top unt(
    .clk(clk),
    .rx(rx),
    .tx(tx),
    .sw(sw),
    .led(led)
);

initial begin
#1.1 // 1
    tbassert(clk, "Clock!");
    tbassert(!led[0], "!Q_vcc_gnd[0]");
    tbassert(!led[1], "!Q_s_gnd[0]");
    tbassert(!led[2], "!Q_s_s[0]");
    tbassert(!led[3], "!Q_vcc_s[0]");
// Test CE
#1 // 2
    tbassert(!clk, "Clock!");
    sw[0] = 1;
    sw[1] = 1;
    sw[2] = 1;
    sw[3] = 1;
#1 // 3
    tbassert(led[0], "Q_vcc_gnd[0]");
    tbassert(!led[1], "!Q_s_gnd[0]");
    tbassert(!led[2], "!Q_s_s[0]");
    tbassert(led[3], "Q_vcc_s[0]");
#1 // 4
    sw[14] = 1;
#1 // 5
    tbassert(led[0], "Q_vcc_gnd[0]");
    tbassert(led[1], "Q_s_gnd[0]");
    tbassert(led[2], "Q_s_s[0]");
    tbassert(led[3], "Q_vcc_s[0]");
#1 // 6
    sw[14] = 0;
    sw[0] = 0;
    sw[1] = 0;
    sw[2] = 0;
    sw[3] = 0;
#1 // 7
    tbassert(!led[0], "!Q_vcc_gnd[0]");
    tbassert(led[1], "Q_s_gnd[0]");
    tbassert(led[2], "Q_s_s[0]");
    tbassert(!led[3], "!Q_vcc_s[0]");
#1 // 8
    sw[14] = 1;
#1 // 9
    tbassert(!led[0], "!Q_vcc_gnd[0]");
    tbassert(!led[1], "!Q_s_gnd[0]");
    tbassert(!led[2], "!Q_s_s[0]");
    tbassert(!led[3], "!Q_vcc_s[0]");
// Test SR
#1 // 10
    sw[0] = 1;
    sw[1] = 1;
    sw[2] = 1;
    sw[3] = 1;
#1 // 11
    tbassert(led[0], "Q_vcc_gnd[0]");
    tbassert(led[1], "Q_s_gnd[0]");
    tbassert(led[2], "Q_s_s[0]");
    tbassert(led[3], "Q_vcc_s[0]");
#1 // 12
    sw[15] = 1;
#1 // 13
    tbassert(led[0], "Q_vcc_gnd[0]");
    tbassert(led[1], "Q_s_gnd[0]");
    tbassert(!led[2], "!Q_s_s[0]");
    tbassert(!led[3], "!Q_vcc_s[0]");
#1 // 14
    sw[14] = 0;
    sw[15] = 0;
#1 // 15
    tbassert(led[0], "Q_vcc_gnd[0]");
    tbassert(led[1], "Q_s_gnd[0]");
    tbassert(!led[2], "!Q_s_s[0]");
    tbassert(led[3], "Q_vcc_s[0]");
#1 // 16
    sw[14] = 1;
#1 // 17
    tbassert(led[0], "Q_vcc_gnd[0]");
    tbassert(led[1], "Q_s_gnd[0]");
    tbassert(led[2], "Q_s_s[0]");
    tbassert(led[3], "Q_vcc_s[0]");
#1  $finish;
end

endmodule
