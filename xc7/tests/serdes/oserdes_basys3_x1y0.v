`include "oserdes_test.v"

`default_nettype none

// ============================================================================

module top
(
input  wire clk,

input  wire rx,
output wire tx,

input  wire [15:0] sw,
output wire [15:0] led,

input  wire [11:0]  in,
output wire [11:0]  out
);

// ============================================================================
// Clock & reset
reg [11:0] rst_sr;

initial rst_sr <= 12'hF;

always @(posedge clk)
    if (sw[0])
        rst_sr <= 12'hF;
    else
        rst_sr <= rst_sr >> 1;

wire CLK1;
wire RST = rst_sr[0];

BUFG clk1(.I(clk), .O(CLK1));

// ============================================================================
// Clocks for OSERDES

// SDR
wire PRE_BUFG_CLKDIV2_1;
wire PRE_BUFG_CLKDIV3_1;
wire PRE_BUFG_CLKDIV4_1;
wire PRE_BUFG_CLKDIV6_1;
wire PRE_BUFG_CLKDIV7_1;
wire PRE_BUFG_CLKDIV8_1;

// DDR
wire PRE_BUFG_CLKDIV4_2;
wire PRE_BUFG_CLKDIV6_2;
wire PRE_BUFG_CLKDIV8_2;

wire CLKDIV2_1;
wire CLKDIV3_1;
wire CLKDIV4_1;
wire CLKDIV6_1;
wire CLKDIV7_1;
wire CLKDIV8_1;

wire CLKDIV4_2;
wire CLKDIV6_2;
wire CLKDIV8_2;

wire O_LOCKED_1;
wire O_LOCKED_2;

wire clk_fb_i1;
wire clk_fb_o1;

wire clk_fb_i2;
wire clk_fb_o2;

PLLE2_ADV #
(
.BANDWIDTH          ("HIGH"),
.COMPENSATION       ("ZHOLD"),

.CLKIN1_PERIOD      (10.0),  // 100MHz

.CLKFBOUT_MULT      (16),
.CLKFBOUT_PHASE     (0),

.CLKOUT0_DIVIDE     (48),

.CLKOUT1_DIVIDE     (64),

.CLKOUT2_DIVIDE     (96),

.CLKOUT3_DIVIDE     (112),

.CLKOUT4_DIVIDE     (128),

.STARTUP_WAIT       ("FALSE")
)
pll1
(
.CLKIN1     (CLK1),
.CLKINSEL   (1),

.RST        (RST),
.PWRDWN     (0),
.LOCKED     (O_LOCKED_1),

.CLKFBIN    (clk_fb_i1),
.CLKFBOUT   (clk_fb_o1),

.CLKOUT0    (PRE_BUFG_CLKDIV3_1),
.CLKOUT1    (PRE_BUFG_CLKDIV4_1),
.CLKOUT2    (PRE_BUFG_CLKDIV6_1),
.CLKOUT3    (PRE_BUFG_CLKDIV7_1),
.CLKOUT4    (PRE_BUFG_CLKDIV8_1)
);

PLLE2_ADV #
(
.BANDWIDTH          ("HIGH"),
.COMPENSATION       ("ZHOLD"),

.CLKIN1_PERIOD      (10.0),  // 100MHz

.CLKFBOUT_MULT      (16),
.CLKFBOUT_PHASE     (0),

.CLKOUT0_DIVIDE     (64),

.CLKOUT1_DIVIDE     (96),

.CLKOUT2_DIVIDE     (128),

.STARTUP_WAIT       ("FALSE")
)
pll2
(
.CLKIN1     (CLK1),
.CLKINSEL   (1),

.RST        (RST),
.PWRDWN     (0),
.LOCKED     (O_LOCKED_2),

.CLKFBIN    (clk_fb_i2),
.CLKFBOUT   (clk_fb_o2),

.CLKOUT0    (PRE_BUFG_CLKDIV4_2),
.CLKOUT1    (PRE_BUFG_CLKDIV6_2),
.CLKOUT2    (PRE_BUFG_CLKDIV8_2)
);

BUFG bufg_clkdiv3_1(.I(PRE_BUFG_CLKDIV3_1), .O(CLKDIV3_1));
BUFG bufg_clkdiv4_1(.I(PRE_BUFG_CLKDIV4_1), .O(CLKDIV4_1));
BUFG bufg_clkdiv6_1(.I(PRE_BUFG_CLKDIV6_1), .O(CLKDIV6_1));
BUFG bufg_clkdiv7_1(.I(PRE_BUFG_CLKDIV7_1), .O(CLKDIV7_1));
BUFG bufg_clkdiv8_1(.I(PRE_BUFG_CLKDIV8_1), .O(CLKDIV8_1));

BUFG bufg_clkdiv4_2(.I(PRE_BUFG_CLKDIV4_2), .O(CLKDIV4_2));
BUFG bufg_clkdiv6_2(.I(PRE_BUFG_CLKDIV6_2), .O(CLKDIV6_2));
BUFG bufg_clkdiv8_2(.I(PRE_BUFG_CLKDIV8_2), .O(CLKDIV8_2));

// ============================================================================
// Test uints
wire [9:0] error;

genvar i;
generate for (i=0; i<8; i=i+1) begin

  localparam DATA_WIDTH = (i == 0) ?   3 :
                          (i == 1) ?   4 :
                          (i == 2) ?   6 :
                          (i == 3) ?   7 :
                          (i == 4) ?   8 :
                          (i == 5) ?   4 :
                          (i == 6) ?   6 :
                        /*(i == 7) ?*/ 8;

  localparam DATA_RATE =  (i < 5) ? "SDR" : "DDR";

  wire CLKDIV = (i == 0) ? CLKDIV3_1 :
                (i == 1) ? CLKDIV4_1 :
                (i == 2) ? CLKDIV6_1 :
                (i == 3) ? CLKDIV7_1 :
                (i == 4) ? CLKDIV8_1 :
                (i == 5) ? CLKDIV4_2 :
                (i == 6) ? CLKDIV6_2 :
              /*(i == 7)*/ CLKDIV8_2;


  oserdes_test #
  (
  .DATA_WIDTH   (DATA_WIDTH),
  .DATA_RATE    (DATA_RATE)
  )
  oserdes_test
  (
  .CLK      (CLK1),
  .CLKDIV   (CLKDIV),
  .RST      (RST),

  .I_DAT   (in[i]),
  .O_DAT   (out[i]),
  .O_ERROR  (error[i])
  );

end endgenerate

// ============================================================================
// IOs
reg [24:0] heartbeat_cnt;

always @(posedge CLK1)
    heartbeat_cnt <= heartbeat_cnt + 1;

assign led[ 0] = !error[0];
assign led[ 1] = !error[1];
assign led[ 2] = !error[2];
assign led[ 3] = !error[3];
assign led[ 4] = !error[4];
assign led[ 5] = !error[5];
assign led[ 6] = !error[6];
assign led[ 7] = !error[7];
assign led[ 8] = heartbeat_cnt[24];
assign led[ 9] = 1'b0;
assign led[10] = 1'b0;
assign led[11] = 1'b0;
assign led[12] = 1'b0;
assign led[13] = 1'b0;
assign led[14] = 1'b0;
assign led[15] = 1'b0;

endmodule

