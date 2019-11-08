`default_nettype none

`define CLKFBOUT_MULT 16

// ============================================================================

module top
(
input  wire clk,

input  wire sw,
output wire [1:0] led,

input  wire in,
output wire out
);

localparam DATA_WIDTH = `DATA_WIDTH_DEFINE;
localparam DATA_RATE = `DATA_RATE_DEFINE;

// ============================================================================
// Clock & reset
reg [3:0] rst_sr;

initial rst_sr <= 4'hF;

wire CLK;

BUFG bufg(.I(clk), .O(CLK));

always @(posedge CLK)
    if (sw)
        rst_sr <= 4'hF;
    else
        rst_sr <= rst_sr >> 1;

wire RST = rst_sr[0];

// ============================================================================
// Clocks for OSERDES

wire PRE_BUFG_CLKX;
wire PRE_BUFG_CLKDIV;

wire CLKX;
wire CLKDIV;

wire O_LOCKED;

wire clk_fb_i;
wire clk_fb_o;

PLLE2_ADV #(
.BANDWIDTH          ("HIGH"),
.COMPENSATION       ("ZHOLD"),

.CLKIN1_PERIOD      (10.0),  // 100MHz

.CLKFBOUT_MULT      (`CLKFBOUT_MULT),
.CLKFBOUT_PHASE     (0),

.CLKOUT0_DIVIDE     (`CLKFBOUT_MULT * DATA_WIDTH),

.CLKOUT1_DIVIDE     (`CLKFBOUT_MULT),

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

BUFG bufg_clk(.I(PRE_BUFG_CLKX), .O(CLKX));
BUFG bufg_clkdiv(.I(PRE_BUFG_CLKDIV), .O(CLKDIV));

// ============================================================================
// Test uints
wire error;

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

.I_DAT   (in),
.O_DAT   (out),
.O_ERROR  (error)
);

// ============================================================================
// IOs
reg [24:0] heartbeat_cnt;

always @(posedge CLK)
    heartbeat_cnt <= heartbeat_cnt + 1;

assign led[0] = !error;
assign led[1] = heartbeat_cnt[24];

endmodule

