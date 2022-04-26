`default_nettype none

`define CLKFBOUT_MULT 2

// ============================================================================

module top
(
input  wire clk,

input  wire rst,

input  wire [7:0] sw,
output wire [9:0] led,

inout wire io
);

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
wire PRE_BUFG_SYSCLK_90;

wire SYSCLK;
wire SYSCLK_90;

wire O_LOCKED;

wire clk_fb_i;
wire clk_fb_o;

localparam DIVIDE_RATE = DATA_RATE == "SDR" ? DATA_WIDTH : DATA_WIDTH / 2;

PLLE2_ADV #(
.BANDWIDTH          ("HIGH"),
.COMPENSATION       ("ZHOLD"),

.CLKIN1_PERIOD      (10.0),  // 100MHz

.CLKFBOUT_MULT      (`CLKFBOUT_MULT),
.CLKOUT0_DIVIDE     (`CLKFBOUT_MULT * 4), // SYSCLK, 25MHz
.CLKOUT1_DIVIDE     (`CLKFBOUT_MULT * 4), // SYSCLK, 25MHz, shifted 90 degrees
.CLKOUT1_PHASE      (90.0),               // SYSCLK, 25MHz, shifted 90 degrees

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
.CLKOUT1    (PRE_BUFG_SYSCLK_90)
);

BUFG bufg_clk(.I(PRE_BUFG_SYSCLK), .O(SYSCLK));
BUFG bufg_clk90(.I(PRE_BUFG_SYSCLK_90), .O(SYSCLK_90));

// ============================================================================
// Test uints
wire INPUT = sw[0];
wire [3:0] SAMPLES;

serdes_test_oversample
(
.SYSCLK     (SYSCLK),
.SYSCLK_90  (SYSCLK_90),
.RST        (RST),

.OUTPUTS    (SAMPLES),

.I_DAT      (INPUT)
);

wire [7:0] MASKED_OUTPUTS = OUTPUTS & MASK;

// ============================================================================
// I/O connections

reg [23:0] heartbeat_cnt;

always @(posedge SYSCLK)
    heartbeat_cnt <= heartbeat_cnt + 1;

assign led[0] = heartbeat_cnt[22];
assign led[4:1] = SAMPLES;

endmodule
