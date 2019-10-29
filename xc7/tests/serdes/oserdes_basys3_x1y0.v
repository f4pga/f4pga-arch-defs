`include "oserdes_test.v"

// ============================================================================

module top
(
input  wire clk,

input  wire sw,
output wire [10:0] led,

input  wire [9:0] in,
output wire [9:0] out
);

// ============================================================================
// Clock & reset
reg [3:0] rst_sr;

initial rst_sr <= 4'hF;

always @(posedge clk)
    if (sw[0])
        rst_sr <= 4'hF;
    else
        rst_sr <= rst_sr >> 1;

wire CLK;
BUFG bufg_clk(.I(clk), .O(CLK));
wire RST = rst_sr[0];

// ============================================================================
// Clocks for OSERDES

wire CLKDIV_2;
wire CLKDIV_3;
wire CLKDIV_4;
wire CLKDIV_5;
wire CLKDIV_6;
wire CLKDIV_7;
wire CLKDIV_8;

wire pll_1_clk_fb_i;
wire pll_1_clk_fb_o;
wire pll_2_clk_fb_i;
wire pll_2_clk_fb_o;

wire locked_1;
wire locked_2;

PLLE2_ADV #
(
.BANDWIDTH          ("HIGH"),
.COMPENSATION       ("ZHOLD"),

.CLKOUT0_DIVIDE     (2),
.CLKOUT0_DUTY_CYCLE (50000),

.CLKOUT1_DIVIDE     (3),
.CLKOUT1_DUTY_CYCLE (50000),

.CLKOUT2_DIVIDE     (4),
.CLKOUT2_DUTY_CYCLE (50000),

.CLKOUT3_DIVIDE     (5),
.CLKOUT3_DUTY_CYCLE (50000),

.CLKOUT4_DIVIDE     (6),
.CLKOUT4_DUTY_CYCLE (50000),

.CLKOUT5_DIVIDE     (7),
.CLKOUT5_DUTY_CYCLE (50000),

.STARTUP_WAIT       ("FALSE")
)
pll_1
(
.CLKIN1     (CLK),
.CLKINSEL   (1),

.RST        (RST),
.PWRDWN     (0),
.LOCKED     (locked_1),

.CLKFBIN    (pll_1_clk_fb_i),
.CLKFBOUT   (pll_1_clk_fb_o),

.CLKOUT0    (CLKDIV_2),
.CLKOUT1    (CLKDIV_3),
.CLKOUT2    (CLKDIV_4),
.CLKOUT3    (CLKDIV_5),
.CLKOUT4    (CLKDIV_6),
.CLKOUT5    (CLKDIV_7)
);

PLLE2_ADV #
(
.BANDWIDTH          ("HIGH"),
.COMPENSATION       ("ZHOLD"),

.CLKOUT0_DIVIDE     (8),
.CLKOUT0_DUTY_CYCLE (50000),

.STARTUP_WAIT       ("FALSE")
)
pll_2
(
.CLKIN1     (CLK),
.CLKINSEL   (1),

.RST        (RST),
.PWRDWN     (0),
.LOCKED     (locked_2),

.CLKFBIN    (pll_2_clk_fb_i),
.CLKFBOUT   (pll_2_clk_fb_o),

.CLKOUT0    (CLKDIV_8)
);

// ============================================================================
// Test uints
wire [9:0] error;

genvar i;
generate for (i=9; i<10; i=i+1) begin

  localparam DATA_WIDTH = (i == 0) ?   2 :
                          (i == 1) ?   3 :
                          (i == 2) ?   4 :
                          (i == 3) ?   5 :
                          (i == 4) ?   6 :
                          (i == 5) ?   7 :
                          (i == 6) ?   8 :
                          (i == 7) ?   4 :
                          (i == 8) ?   6 :
                        /*(i == 9) ?*/ 8;

  wire CLKDIV = (i == 0) ?   CLKDIV_2 :
                (i == 1) ?   CLKDIV_3 :
                (i == 2) ?   CLKDIV_4 :
                (i == 3) ?   CLKDIV_5 :
                (i == 4) ?   CLKDIV_6 :
                (i == 5) ?   CLKDIV_7 :
                (i == 6) ?   CLKDIV_8 :
                (i == 7) ?   CLKDIV_4 :
                (i == 8) ?   CLKDIV_6 :
              /*(i == 9) ?*/ CLKDIV_8;

  localparam DATA_RATE =  (i <  7) ? "SDR" : "DDR";

  wire out_data;
  oserdes_test #
  (
  .DATA_WIDTH   (DATA_WIDTH),
  .DATA_RATE    (DATA_RATE)
  )
  oserdes_test
  (
  .CLK      (CLK),
  .CLKDIV   (CLKDIV),
  .RST      (RST),

  .I_DAT   (in[i]),
  .O_DAT   (out_data),
  .O_ERROR  (error[i])
  );

  OBUF obuf (.I(out_data), .O(out[i]));

end endgenerate

// ============================================================================
// IOs
reg [24:0] heartbeat_cnt;

always @(posedge CLK)
    heartbeat_cnt <= heartbeat_cnt + 1;

assign led[ 0] = !error[0];
assign led[ 1] = !error[1];
assign led[ 2] = !error[2];
assign led[ 3] = !error[3];
assign led[ 4] = !error[4];
assign led[ 5] = !error[5];
assign led[ 6] = !error[6];
assign led[ 7] = !error[7];
assign led[ 8] = !error[8];
assign led[ 9] = !error[9];
assign led[10] = heartbeat_cnt[23];

endmodule

