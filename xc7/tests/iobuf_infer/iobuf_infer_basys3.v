/*
In this test a single IOBUF is controlled by switches. There is also one
input (connected to a LED) and one oputput (controlled by a switch) that.
can be used for verification of 3-state I/O.

This test requires a physical jumper to be installed on the Basys3 board.
Depending on which pins are connected we have different truth tables of
LED output w.r.t. switch input.

Truth table. When JC.1 is connected to JC.2:

SW2 SW1 SW0 | LED1 LED0
 0   0   0  |  0    0
 0   0   1  |  1    1
 0   1   0  |  x    x
 0   1   1  |  x    x
 1   0   0  |  0    0
 1   0   1  |  1    1
 1   1   0  |  x    x
 1   1   1  |  x    x


Truth table. When JC.3 is connected to JC.2:

SW2 SW1 SW0 | LED1 LED0
 0   0   0  |  x    0
 0   0   1  |  x    1
 0   1   0  |  x    0
 0   1   1  |  x    0
 1   0   0  |  x    0
 1   0   1  |  x    1
 1   1   0  |  x    1
 1   1   1  |  x    1

*/
`default_nettype none


// ============================================================================

module top
(
input  wire clk,

input  wire rx,
output wire tx,

input  wire [15:0] sw,
output wire [15:0] led,

input  wire jc1,
inout  wire jc2,
output wire jc3,
input  wire jc4  // unused
);

// ============================================================================
// IOBUF (to be swferred)
wire io_i;
wire io_o;
wire io_t;

assign io_o = jc2;
assign jc2  = (io_t == 1'b0) ? io_i : 1'bz;

// ============================================================================

// SW0 controls IOBUF.I
assign io_i = sw[0];
// SW1 controls IOBUF.T
assign io_t = sw[1];
// SW2 controls OBUF.I (JC.3)
assign jc3  = sw[2];

// LED0 swdicates IOBUF.O
assign led[0] = io_o;

// LED1 is connected to JC.1
assign led[1] = jc1;

// Unused IOs - SW->LED passthrough.
assign led[15:2] = {sw[15:3], 1'd0};

endmodule

