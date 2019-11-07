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

input  wire in,
output wire out
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

wire CLK;
wire RST = rst_sr[0];

BUFG bufg(.I(clk), .O(CLK));

// ============================================================================
// Clocks for OSERDES

wire PRE_BUFG_CLKX;
wire PRE_BUFG_CLKDIV;

wire CLKX;
wire CLKDIV;

wire O_LOCKED;

wire clk_fb_i;
wire clk_fb_o;

PLLE2_ADV #
(
.BANDWIDTH          ("HIGH"),
.COMPENSATION       ("ZHOLD"),

.CLKIN1_PERIOD      (10.0),  // 100MHz

.CLKFBOUT_MULT      (16),
.CLKFBOUT_PHASE     (0),

.CLKOUT0_DIVIDE     (128),

.CLKOUT1_DIVIDE     (16),

.STARTUP_WAIT       ("FALSE")
)
pll
(
.CLKIN1     (CLK),
.CLKINSEL   (1),

.RST        (RST),
.PWRDWN     (0),
.LOCKED     (O_LOCKED),

.CLKFBIN    (clk_fb_i),
.CLKFBOUT   (clk_fb_o),

.CLKOUT0    (PRE_BUFG_CLKDIV),
.CLKOUT1    (PRE_BUFG_CLKX)
);

BUFG bufg_clk2(.I(PRE_BUFG_CLKX), .O(CLKX));
BUFG bufg_clkdiv8_2(.I(PRE_BUFG_CLKDIV), .O(CLKDIV));

// ============================================================================
// Test uints
wire error;


localparam DATA_WIDTH = 8;
localparam DATA_RATE = "SDR";


oserdes_test #
(
.DATA_WIDTH   (DATA_WIDTH),
.DATA_RATE    (DATA_RATE)
)
oserdes_test
(
.CLK      (CLKX),
.CLKDIV   (CLKDIV),
.RST      (RST),

.I_DAT   (in[0]),
.O_DAT   (out[0]),
.O_ERROR  (error)
);

// ============================================================================
// IOs
reg [24:0] heartbeat_cnt;

always @(posedge CLK)
    heartbeat_cnt <= heartbeat_cnt + 1;

assign led[0] = !error;
assign led[1] = heartbeat_cnt[24];
assign led[15:2] = 0;

endmodule

