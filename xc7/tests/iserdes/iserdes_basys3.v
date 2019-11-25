`default_nettype none

`define CLKFBOUT_MULT 8

// ============================================================================

module top
(
input  wire clk,

input  wire rst,

input  wire [7:0] sw,
output wire [8:0] led,

input  wire in,
output wire out
);

localparam DATA_WIDTH = `DATA_WIDTH_DEFINE;
localparam DATA_RATE =  `DATA_RATE_DEFINE;

// ============================================================================
// Clock & reset
reg [3:0] rst_sr;

initial rst_sr <= 4'hF;

wire CLK;

BUFG bufg(.I(clk), .O(CLK));

always @(posedge CLK)
    if (rst)
        rst_sr <= 4'hF;
    else
        rst_sr <= rst_sr >> 1;

wire RST = rst_sr[0];

// ============================================================================
// Clocks for ISERDES

wire PRE_BUFG_SYSCLK;
wire PRE_BUFG_CLKDIV;

wire SYSCLK;
wire CLKDIV;

wire O_LOCKED;

wire clk_fb_i;
wire clk_fb_o;

PLLE2_ADV #(
.BANDWIDTH          ("HIGH"),
.COMPENSATION       ("ZHOLD"),

.CLKIN1_PERIOD      (10.0),  // 100MHz

.CLKFBOUT_MULT      (`CLKFBOUT_MULT),

.CLKOUT0_DIVIDE     (`CLKFBOUT_MULT / 4),

.CLKOUT1_DIVIDE     (`CLKFBOUT_MULT),

.STARTUP_WAIT       ("FALSE"),

.DIVCLK_DIVIDE      (1'd1)
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

.CLKOUT0    (PRE_BUFG_SYSCLK),
.CLKOUT1    (PRE_BUFG_CLKDIV)
);

BUFG bufg_clk(.I(PRE_BUFG_SYSCLK), .O(SYSCLK));
BUFG bufg_clkdiv(.I(PRE_BUFG_CLKDIV), .O(CLKDIV));

// ============================================================================
// Test uints
wire [7:0] OUTPUTS;
wire [7:0] INPUTS = sw[7:0];

iserdes_test #
(
.DATA_WIDTH   (DATA_WIDTH),
.DATA_RATE    (DATA_RATE)
)
iserdes_test
(
.SYSCLK     (SYSCLK),
.CLKDIV     (CLKDIV),
.RST        (RST),

.OUTPUTS    (OUTPUTS),
.INPUTS     (INPUTS),

.I_DAT      (in),
.O_DAT      (out)
);

// ============================================================================
// I/O connections

reg [23:0] heartbeat_cnt;

always @(posedge SYSCLK)
    heartbeat_cnt <= heartbeat_cnt + 1;


assign led[0] = heartbeat_cnt[22];
assign led[8:1] = OUTPUTS;

endmodule
