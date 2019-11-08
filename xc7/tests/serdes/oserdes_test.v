`default_nettype none

`define CLKFBOUT_MULT 16

// ============================================================================

module oserdes_test #
(
parameter DATA_WIDTH    = 8,
parameter DATA_RATE     = "SDR",
parameter ERROR_HOLD    = 2500000
)
(
// "Hi speed" clock and reset
input  wire CLK,
input  wire RST,

// Data pin
input  wire I_DAT,
output wire O_DAT,

// Error indicator
output wire O_ERROR
);

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

// The clock enable signal for the "hi speed" clock domain.
reg  clkdiv_r;
wire ce;

always @(posedge CLK)
    clkdiv_r <= CLKDIV;

assign ce = clkdiv_r && !CLKDIV;


// ============================================================================
// Data source

reg         lfsr_stb;
wire [7:0]  lfsr_dat;

lfsr lfsr
(
.CLK    (CLK),
.RST    (RST),
.CE     (ce),

.O      (lfsr_dat)
);

always @(posedge CLK)
    if (RST)
        lfsr_stb <= 1'b0;
    else
        lfsr_stb <= ce;

// Synchronize generated data wordst to the CLKDIV
reg  [7:0] ser_dat;

always @(posedge CLKDIV)
    ser_dat <= lfsr_dat;

// ============================================================================
// OSERDES

// OSERDES reset generator (required for it to work properly!)
reg [3:0]  ser_rst_sr;
initial    ser_rst_sr <= 4'hF;

always @(posedge CLKDIV or posedge RST)
    if (RST) ser_rst_sr <= 4'hF;
    else     ser_rst_sr <= ser_rst_sr >> 1;

wire ser_rst = ser_rst_sr[0];

// OSERDES
wire ser_oq;
wire ser_tq;

OSERDESE2 #(
.DATA_RATE_OQ   (DATA_RATE),
.DATA_WIDTH     (DATA_WIDTH),
.DATA_RATE_TQ   ((DATA_RATE == "DDR" && DATA_WIDTH == 4) ? "DDR" : "SDR"),
.TRISTATE_WIDTH ((DATA_RATE == "DDR" && DATA_WIDTH == 4) ? 4 : 1)
)
oserdes
(
.CLK    (CLKX),
.CLKDIV (CLKDIV),
.RST    (ser_rst),

.OCE    (1'b1),
.D1     (ser_dat[0]),
.D2     (ser_dat[1]),
.D3     (ser_dat[2]),
.D4     (ser_dat[3]),
.D5     (ser_dat[4]),
.D6     (ser_dat[5]),
.D7     (ser_dat[6]),
.D8     (ser_dat[7]),
.OQ     (ser_oq),

.TCE    (1'b1),
.T1     (1'b0), // All 0 to keep OBUFT always on.
.T2     (1'b0),
.T3     (1'b0),
.T4     (1'b0),
.TQ     (ser_tq)
);

// ============================================================================
// IOB

wire iob_i;

OBUF obuf (
    .I(ser_oq),
    .O(O_DAT)
);

IBUF ibuf (
    .I(I_DAT),
    .O(iob_i)
);

// ============================================================================
// Reference data serializer
reg  [7:0]  ref_sr;
wire        ref_o;

always @(posedge CLK)
    if (RST)
        ref_sr <= 0;
    else if (ce)
        ref_sr <= lfsr_dat;
    else
        ref_sr <= ref_sr >> 1;

assign ref_o = ref_sr[0];

// ============================================================================
// Data comparator

comparator #
(
.ERROR_COUNT    (16),
.ERROR_HOLD     (ERROR_HOLD)
)
comparator
(
.CLK    (CLK),
.RST    (RST),

.I_DAT_REF  (ref_o),
.I_DAT_IOB  (I_DAT),

.O_ERROR    (O_ERROR)
);

endmodule

