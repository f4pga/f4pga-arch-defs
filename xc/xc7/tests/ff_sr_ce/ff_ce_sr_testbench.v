`timescale 1ns/1ps
`default_nettype none
module test;

localparam NUM_FF = 4;

`include "../../../../library/tbassert.v"

reg clk = 0;
reg rx = 1;
reg [13:0] sw = 0;
reg ce = 0;
reg sr = 0;

wire tx;
wire [15:0] led;


// clock generation
always #1 clk=~clk;


top unt(
    .clk(clk),
    .rx(rx),
    .tx(tx),
    .sw({sr, ce, sw}),
    .led(led)
);

wire [4*NUM_FF-1:0] D;
wire [NUM_FF-1:0] Q_vcc_gnd;
wire [NUM_FF-1:0] Q_s_gnd;
wire [NUM_FF-1:0] Q_s_s;
wire [NUM_FF-1:0] Q_vcc_s;

assign Q_vcc_gnd[0]        = led[0];
assign Q_s_gnd[0]          = led[1];
assign Q_s_s[0]            = led[2];
assign Q_vcc_s[0]          = led[3];
assign Q_vcc_gnd[1]        = led[4];
assign Q_vcc_gnd[NUM_FF-1] = led[5];
assign Q_s_gnd[NUM_FF-1]   = led[6];
assign Q_s_s[NUM_FF-1]     = led[7];
assign Q_vcc_s[NUM_FF-1]   = led[8];

wire xorQ = led[9];
wire orQ = led[10];
wire andQ = led[11];

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
    tbassert(!Q_vcc_gnd[0], "!Q_vcc_gnd[0]");
    tbassert(!Q_s_gnd[0], "!Q_s_gnd[0]");
    tbassert(!Q_s_s[0], "!Q_s_s[0]");
    tbassert(!Q_vcc_s[0], "!Q_vcc_s[0]");
    tbassert(!xorQ, "^Q == 0");
    tbassert(!orQ, "|Q == 0");
    tbassert(!andQ, "&Q == 0");
    tbassert(xorQ == xorD, "^Q == xorD");
// Test CE
#1 // 2
    tbassert(!clk, "Clock!");
    sw[0] = 1;
    sw[1] = 1;
    sw[2] = 1;
    sw[3] = 1;
#1 // 3
    tbassert(Q_vcc_gnd[0], "Q_vcc_gnd[0]");
    tbassert(!Q_s_gnd[0], "!Q_s_gnd[0]");
    tbassert(!Q_s_s[0], "!Q_s_s[0]");
    tbassert(Q_vcc_s[0], "Q_vcc_s[0]");

    tbassert(orQ, "|Q == 1");
    tbassert(!andQ, "&Q == 0");
#1 // 4
    ce = 1;
#1 // 5
    tbassert(Q_vcc_gnd[0], "Q_vcc_gnd[0]");
    tbassert(Q_s_gnd[0], "Q_s_gnd[0]");
    tbassert(Q_s_s[0], "Q_s_s[0]");
    tbassert(Q_vcc_s[0], "Q_vcc_s[0]");

    tbassert(xorQ == xorD, "^Q == xorD");
    tbassert(orQ, "|Q == 1");
    tbassert(!andQ, "&Q == 0");
#1 // 6
    ce = 0;
    sw[0] = 0;
    sw[1] = 0;
    sw[2] = 0;
    sw[3] = 0;
#1 // 7
    tbassert(!Q_vcc_gnd[0], "!Q_vcc_gnd[0]");
    tbassert(Q_s_gnd[0], "Q_s_gnd[0]");
    tbassert(Q_s_s[0], "Q_s_s[0]");
    tbassert(!Q_vcc_s[0], "!Q_vcc_s[0]");

    tbassert(orQ, "|Q == 1");
    tbassert(!andQ, "&Q == 0");
#1 // 8
    ce = 1;
#1 // 9
    tbassert(!Q_vcc_gnd[0], "!Q_vcc_gnd[0]");
    tbassert(!Q_s_gnd[0], "!Q_s_gnd[0]");
    tbassert(!Q_s_s[0], "!Q_s_s[0]");
    tbassert(!Q_vcc_s[0], "!Q_vcc_s[0]");

    tbassert(xorQ == xorD, "^Q == xorD");
    tbassert(!orQ, "|Q == 0");
    tbassert(!andQ, "&Q == 0");
// Test SR
#1 // 10
    sw[0] = 1;
    sw[1] = 1;
    sw[2] = 1;
    sw[3] = 1;
#1 // 11
    tbassert(Q_vcc_gnd[0], "Q_vcc_gnd[0]");
    tbassert(Q_s_gnd[0], "Q_s_gnd[0]");
    tbassert(Q_s_s[0], "Q_s_s[0]");
    tbassert(Q_vcc_s[0], "Q_vcc_s[0]");

    tbassert(orQ, "|Q == 1");
    tbassert(!andQ, "&Q == 0");
#1 // 12
    sr = 1;
#1 // 13
    tbassert(Q_vcc_gnd[0], "Q_vcc_gnd[0]");
    tbassert(Q_s_gnd[0], "Q_s_gnd[0]");
    tbassert(!Q_s_s[0], "!Q_s_s[0]");
    tbassert(!Q_vcc_s[0], "!Q_vcc_s[0]");

    tbassert(xorQ == xorD, "^Q == xorD");
    tbassert(orQ, "|Q == 1");
    tbassert(!andQ, "&Q == 0");
#1 // 14
    ce = 0;
    sr = 0;
#1 // 15
    tbassert(Q_vcc_gnd[0], "Q_vcc_gnd[0]");
    tbassert(Q_s_gnd[0], "Q_s_gnd[0]");
    tbassert(!Q_s_s[0], "!Q_s_s[0]");
    tbassert(Q_vcc_s[0], "Q_vcc_s[0]");

    tbassert(orQ, "|Q == 1");
    tbassert(!andQ, "&Q == 0");
#1 // 16
    ce = 1;
#1 // 17
    tbassert(Q_vcc_gnd[0], "Q_vcc_gnd[0]");
    tbassert(Q_s_gnd[0], "Q_s_gnd[0]");
    tbassert(Q_s_s[0], "Q_s_s[0]");
    tbassert(Q_vcc_s[0], "Q_vcc_s[0]");

    tbassert(xorQ == xorD, "^Q == xorD");
    tbassert(orQ, "|Q == 1");
    tbassert(!andQ, "&Q == 0");
#1 // 18
    sw[13:0] = 14'b11_1111_1111_1111;
#1 // 19
    tbassert(Q_vcc_gnd[0], "Q_vcc_gnd[0]");
    tbassert(Q_s_gnd[0], "Q_s_gnd[0]");
    tbassert(Q_s_s[0], "Q_s_s[0]");
    tbassert(Q_vcc_s[0], "Q_vcc_s[0]");
    tbassert(Q_vcc_gnd[1], "Q_vcc_gnd[1]");
    tbassert(Q_vcc_gnd[NUM_FF-1], "Q_vcc_gnd[-1]");
    tbassert(Q_s_gnd[NUM_FF-1], "Q_s_gnd[-1]");
    tbassert(Q_s_s[NUM_FF-1], "Q_s_s[-1]");
    tbassert(Q_vcc_s[NUM_FF-1], "Q_vcc_s[-1]");

    tbassert(xorQ == xorD, "^Q == xorD");
    tbassert(orQ, "|Q == 1");
    tbassert(andQ, "&Q == 1");
#1  $finish;
end

endmodule
