`timescale 1 ns / 1 ps
`default_nettype none

`ifndef VCDFILE
`define VCDFILE "testbench_lcu_tb.vcd"
`endif

module tb;

`include "../../../../library/tbassert.v"

// ============================================================================

reg clk;
reg thresh_sw;

reg [7:0] threshold, counter;

initial clk <= 1'd0;
initial thresh_sw <= 1'd0;
initial threshold <= 8'd0;
initial counter <= 8'd0;
always #5 clk <= !clk;
always #1000 thresh_sw <= !thresh_sw;

initial begin
  $dumpfile(`VCDFILE);
  $dumpvars;
  #50000 $finish();
end

// ============================================================================
// DUT
wire gtu, gts, ltu, lts, geu, ges, leu, les;


top dut
(
.count      (clk),
.count_sw   (1'b0),
.thresh_sw  (thresh_sw),
.gtu        (gtu),
.gts        (gts),
.ltu        (ltu),
.lts        (lts),
.geu        (geu),
.ges        (ges),
.leu        (leu),
.les        (les)
);

always @(posedge clk) begin
  counter <= counter + 1;

  if (thresh_sw)
    threshold <= threshold + 1;

  tbassert((counter > threshold) == gtu, gtu);
  tbassert(($signed(counter) > $signed(threshold)) == gts, gts);
  tbassert((counter < threshold) == ltu, ltu);
  tbassert(($signed(counter) < $signed(threshold)) == lts, lts);
  tbassert((counter >= threshold) == geu, geu);
  tbassert(($signed(counter) >= $signed(threshold)) == ges, ges);
  tbassert((counter <= threshold) == leu, leu);
  tbassert(($signed(counter) <= $signed(threshold)) == les, les);
end

// ============================================================================

endmodule

