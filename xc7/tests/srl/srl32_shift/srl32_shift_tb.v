`timescale 1 ns / 1 ps
`default_nettype none

`ifndef VCDFILE
`define VCDFILE "testbench_srl32_shift_tb.vcd"
`endif

module tb;

`include "../../../../library/tbassert.v"

// ============================================================================

reg clk;
initial clk <= 1'd0;
always #5 clk <= !clk;

initial begin
  $dumpfile(`VCDFILE);
  $dumpvars;
  #50000 $finish();
end

// ============================================================================
// DUT
wire [15:0] led;
wire [ 7:0] error;

top dut
(
.clk    (clk),
.rx     (1'b1),
.tx     (),
.sw     (16'd0),
.led    (led)
);

assign error = led[7:0];

always @(posedge clk)
  tbassert((|error == 0), error);

// ============================================================================

endmodule

