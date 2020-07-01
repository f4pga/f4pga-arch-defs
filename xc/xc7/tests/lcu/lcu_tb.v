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

reg [31:0] threshold, threshold_down, counter, counter_down;

initial clk <= 1'd0;
initial thresh_sw <= 1'd0;
initial threshold <= 32'd0;
initial threshold_down <= 32'd0;
initial counter <= 32'd0;
initial counter_down <= 32'd0;
always #5 clk <= !clk;
always #500 thresh_sw <= !thresh_sw;

initial begin
  $dumpfile(`VCDFILE);
  $dumpvars;
  #500000 $finish();
end

// ============================================================================
// DUT
wire gtu, gts, ltu, lts, geu, ges, leu, les, zero, max;
wire gtu_n, gts_n, ltu_n, lts_n, geu_n, ges_n, leu_n, les_n, zero_n, max_n;


top dut
(
.count      (clk),
.count_sw   (thresh_sw),
.thresh_sw  (thresh_sw),
.gtu        (gtu),
.gts        (gts),
.ltu        (ltu),
.lts        (lts),
.geu        (geu),
.ges        (ges),
.leu        (leu),
.les        (les),
.zero       (zero),
.max        (max),
.gtu_n      (gtu_n),
.gts_n      (gts_n),
.ltu_n      (ltu_n),
.lts_n      (lts_n),
.geu_n      (geu_n),
.ges_n      (ges_n),
.leu_n      (leu_n),
.les_n      (les_n),
.zero_n     (zero_n),
.max_n      (max_n)
);

always @(posedge clk) begin

  if (thresh_sw) begin
    counter <= counter + 1;
    counter_down <= counter_down - 1;
    threshold <= counter - 32'd31;
    threshold_down <= counter_down + 32'd31;
  end else begin
    threshold <= threshold + 1;
    threshold_down <= threshold_down - 1;
  end

  tbassert((counter == 32'b0) == zero, counter);
  tbassert((counter == 32'hFFFFFFFF) == max, counter);
  tbassert((counter > threshold) == gtu, gtu);
  tbassert(($signed(counter) > $signed(threshold)) == gts, gts);
  tbassert((counter < threshold) == ltu, ltu);
  tbassert(($signed(counter) < $signed(threshold)) == lts, lts);
  tbassert((counter >= threshold) == geu, geu);
  tbassert(($signed(counter) >= $signed(threshold)) == ges, ges);
  tbassert((counter <= threshold) == leu, leu);
  tbassert(($signed(counter) <= $signed(threshold)) == les, les);


  tbassert((counter_down == 32'b0) == zero_n, counter);
  tbassert((counter_down == 32'hFFFFFFFF) == max_n, counter);
  tbassert((counter_down > threshold_down) == gtu_n, gtu_n);
  tbassert(($signed(counter_down) > $signed(threshold_down)) == gts_n, gts_n);
  tbassert((counter_down < threshold_down) == ltu_n, ltu_n);
  tbassert(($signed(counter_down) < $signed(threshold_down)) == lts_n, lts_n);
  tbassert((counter_down >= threshold_down) == geu_n, geu_n);
  tbassert(($signed(counter_down) >= $signed(threshold_down)) == ges_n, ges_n);
  tbassert((counter_down <= threshold_down) == leu_n, leu_n);
  tbassert(($signed(counter_down) <= $signed(threshold_down)) == les_n, les_n);
end

// ============================================================================

endmodule

