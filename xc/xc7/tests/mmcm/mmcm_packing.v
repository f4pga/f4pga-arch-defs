`default_nettype none

// ============================================================================

module top
(
input  wire clk,

input  wire [7:0] sw,
output wire [7:0] led,

input  wire jc1,
output wire jc2,
input  wire jc3,
output wire jc4
);

// ============================================================================
// MMCM

wire clk_fb;

wire [3:0] oclk;
wire [3:0] gclk;

MMCME2_ADV #
(
.BANDWIDTH          ("HIGH"),
.COMPENSATION       ("INTERNAL"),

.CLKIN1_PERIOD      (10.0),
.CLKIN2_PERIOD      (10.0),

.CLKFBOUT_MULT_F    (10.5),
.CLKFBOUT_PHASE     (0),

.CLKOUT0_DIVIDE_F   (12.5),
.CLKOUT0_DUTY_CYCLE (0.50),
.CLKOUT0_PHASE      (45.0),

.CLKOUT1_DIVIDE     (32),
.CLKOUT1_DUTY_CYCLE (0.53125),
.CLKOUT1_PHASE      (90.0),

.CLKOUT2_DIVIDE     (48),
.CLKOUT2_DUTY_CYCLE (0.50),
.CLKOUT2_PHASE      (135.0),

.CLKOUT3_DIVIDE     (64),
.CLKOUT3_DUTY_CYCLE (0.50),
.CLKOUT3_PHASE      (45.0),

.STARTUP_WAIT       ("FALSE")
)
mmcm
(
.CLKIN1     (clk),
.CLKIN2     (clk),
.CLKINSEL   (1'b0),

.RST        (sw[0]),
.PWRDWN     (1'b0),

.CLKFBIN    (clk_fb),
.CLKFBOUT   (clk_fb),

.CLKOUT0    (oclk[0]),
.CLKOUT1    (oclk[1]),
.CLKOUT2    (oclk[2]),
.CLKOUT3    (oclk[3])
);

// ============================================================================
// Outputs

genvar i;
generate for (i=0; i<4; i=i+1) begin

  BUFG bufg (.I(oclk[i]), .O(gclk[i]));

  reg r;
  always @(posedge gclk[i])
    r <= ~r;

  assign led[i] = r;

end endgenerate

// Unused
assign led[4] = 1'b0;
assign led[5] = 1'b0;
assign led[6] = 1'b0;
assign led[7] = |sw;

assign jc2 = jc1;
assign jc4 = jc3;

endmodule

