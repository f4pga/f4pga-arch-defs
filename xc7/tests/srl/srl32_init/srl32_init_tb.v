`timescale 1 ns / 1 ps
`default_nettype none

module test;

`include "../../../../library/tbassert.v"

// ============================================================================

reg clk;
initial clk <= 1'd0;
always #5 clk <= !clk;

// ============================================================================
// DUT
wire [15:0] led;
wire error;

top #
(
.PRESCALER  (4)
)
dut
(
.clk    (clk),
.rx     (1'b1),
.tx     (),
.sw     (16'd0),
.led    (led)
);

assign error = |led[7:0];

always @(posedge CLK)
    tbassert(error == 1'd0);

// ============================================================================

endmodule

