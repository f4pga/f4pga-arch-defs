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
input  wire [11:0] in,
output wire [11:0] out,

input  wire jc1,
inout  wire jc2,
output wire jc3
);

// ============================================================================
// IOBUF
wire io_i;
wire io_o;
wire io_t;

IOBUF iobuf
(
.I  (io_i),
.T  (io_t),
.O  (io_o),
.IO (jc2) // Directly to the module output
);

// ============================================================================

// SW0 controls IOBUF.I
assign io_i = in[0];
// SW1 controls IOBUF.T
assign io_t = in[1];
// SW2 controls OBUF.I (JC.3)
assign jc3  = in[2];

// LED0 indicates IOBUF.O
assign out[0] = io_o;
// LED1 is connected to JC.1
assign out[1] = jc1;

// Unused IOs - SW->LED passthrough.
assign out[11:2] = {in[11:3], 1'd0};

endmodule

