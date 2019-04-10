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


top unt(
    .clk(clk),
    .rx(rx),
    .tx(tx),
    .sw(sw),
    .led(led)
);

wire [4*NUM_FF-1:0] D;

genvar i;
generate for(i = 0; i < NUM_FF; i=i+1) begin:ff
    assign D[4*i+0] = sw[(4*i+0) % 14];
    assign D[4*i+1] = sw[(4*i+1) % 14];
    assign D[4*i+2] = sw[(4*i+2) % 14];
    assign D[4*i+3] = sw[(4*i+3) % 14];
end endgenerate

wire xorD = ^D;
wire orD = |D;
wire andD = &D;

always begin
    #1
    $monitor("1:%d %d %d %d %d %d %d %d %d %d %d %d %d", $time, clk,    sw[14], led[0],  led[1], led[2], led[3], led[9], xorD,   led[10], orD,    led[11], andD);
end

initial begin
    $dumpfile("testbench_ff_ce_sr_4_tb.vcd");
    $dumpvars;
#1.1 // 1
    tbassert(clk, "Clock!");
    tbassert(!led[0], "!Q_vcc_gnd[0]");
    tbassert(!led[1], "!Q_s_gnd[0]");
    tbassert(!led[2], "!Q_s_s[0]");
    tbassert(!led[3], "!Q_vcc_s[0]");
    tbassert(!led[9], "^Q == 0");
    tbassert(!led[10], "|Q == 0");
    tbassert(!led[11], "&Q == 0");
    tbassert(led[9] == xorD, "^Q == xorD");
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

    tbassert(led[10], "|Q == 1");
    tbassert(!led[11], "&Q == 0");
#1 // 4
    sw[14] = 1;
#1 // 5
    tbassert(led[0], "Q_vcc_gnd[0]");
    tbassert(led[1], "Q_s_gnd[0]");
    tbassert(led[2], "Q_s_s[0]");
    tbassert(led[3], "Q_vcc_s[0]");

    tbassert(led[9] == xorD, "^Q == xorD");
    tbassert(led[10], "|Q == 1");
    tbassert(!led[11], "&Q == 0");
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

    tbassert(led[10], "|Q == 1");
    tbassert(!led[11], "&Q == 0");
#1 // 8
    sw[14] = 1;
#1 // 9
    tbassert(!led[0], "!Q_vcc_gnd[0]");
    tbassert(!led[1], "!Q_s_gnd[0]");
    tbassert(!led[2], "!Q_s_s[0]");
    tbassert(!led[3], "!Q_vcc_s[0]");

    tbassert(led[9] == xorD, "^Q == xorD");
    tbassert(!led[10], "|Q == 0");
    tbassert(!led[11], "&Q == 0");
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

    tbassert(led[10], "|Q == 1");
    tbassert(!led[11], "&Q == 0");
#1 // 12
    sw[15] = 1;
#1 // 13
    tbassert(led[0], "Q_vcc_gnd[0]");
    tbassert(led[1], "Q_s_gnd[0]");
    tbassert(!led[2], "!Q_s_s[0]");
    tbassert(!led[3], "!Q_vcc_s[0]");

    tbassert(led[9] == xorD, "^Q == xorD");
    tbassert(led[10], "|Q == 1");
    tbassert(!led[11], "&Q == 0");
#1 // 14
    sw[14] = 0;
    sw[15] = 0;
#1 // 15
    tbassert(led[0], "Q_vcc_gnd[0]");
    tbassert(led[1], "Q_s_gnd[0]");
    tbassert(!led[2], "!Q_s_s[0]");
    tbassert(led[3], "Q_vcc_s[0]");

    tbassert(led[10], "|Q == 1");
    tbassert(!led[11], "&Q == 0");
#1 // 16
    sw[14] = 1;
#1 // 17
    tbassert(led[0], "Q_vcc_gnd[0]");
    tbassert(led[1], "Q_s_gnd[0]");
    tbassert(led[2], "Q_s_s[0]");
    tbassert(led[3], "Q_vcc_s[0]");

    tbassert(led[9] == xorD, "^Q == xorD");
    tbassert(led[10], "|Q == 1");
    tbassert(!led[11], "&Q == 0");
#1 // 18
    sw[13:0] = 14'b11_1111_1111_1111;
#1 // 19
    tbassert(led[0], "Q_vcc_gnd[0]");
    tbassert(led[1], "Q_s_gnd[0]");
    tbassert(led[2], "Q_s_s[0]");
    tbassert(led[3], "Q_vcc_s[0]");
    tbassert(led[4], "Q_vcc_gnd[1]");
    tbassert(led[5], "Q_vcc_gnd[-1]");
    tbassert(led[6], "Q_s_gnd[-1]");
    tbassert(led[7], "Q_s_s[-1]");
    tbassert(led[8], "Q_vcc_s[-1]");

    tbassert(led[9] == xorD, "^Q == xorD");
    tbassert(led[10], "|Q == 1");
    tbassert(led[11], "&Q == 1");
#1  $finish;
end

endmodule
