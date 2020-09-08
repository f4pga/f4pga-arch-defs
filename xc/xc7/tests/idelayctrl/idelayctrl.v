`default_nettype none

`define CLKFBOUT_MULT 2

// ============================================================================

module top
(
    input  wire clk,

    input  wire rst,

    input  wire [1:0] sw,
    output wire [9:0] led,
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
wire PRE_BUFG_CLKDIV;
wire PRE_BUFG_REFCLK;

wire SYSCLK;
wire CLKDIV;
wire REFCLK;

wire clk_fb_i;
wire clk_fb_o;

PLLE2_ADV #(
.BANDWIDTH          ("HIGH"),
.COMPENSATION       ("ZHOLD"),

.CLKIN1_PERIOD      (10.0),  // 100MHz

.CLKFBOUT_MULT      (`CLKFBOUT_MULT),
.CLKOUT0_DIVIDE     (`CLKFBOUT_MULT / 2), // SYSCLK, 200MHz (Fast clock)
.CLKOUT1_DIVIDE     ((`CLKFBOUT_MULT * 4) / 2), // CLKDIV, 50MHz (Slow clock)
.CLKOUT2_DIVIDE     (`CLKFBOUT_MULT / 2), // REFCLK (IDELAYCTRL), 200 MHz

.STARTUP_WAIT       ("FALSE"),

.DIVCLK_DIVIDE      (1'd1)
)
pll
(
.CLKIN1     (CLK),
.CLKINSEL   (1),

.RST        (RST),
.PWRDWN     (0),

.CLKFBIN    (clk_fb_i),
.CLKFBOUT   (clk_fb_o),

.CLKOUT0    (PRE_BUFG_SYSCLK),
.CLKOUT1    (PRE_BUFG_CLKDIV),
.CLKOUT2    (PRE_BUFG_REFCLK)
);

BUFG bufg_clk(.I(PRE_BUFG_SYSCLK), .O(SYSCLK));
BUFG bufg_clkdiv(.I(PRE_BUFG_CLKDIV), .O(CLKDIV));
BUFG bufg_refclk(.I(PRE_BUFG_REFCLK), .O(REFCLK));

wire RDY_1;
wire RDY_2;

IDELAYCTRL idelayctrl_1 (
    .REFCLK(REFCLK),
    .RDY(RDY_1)
);

IDELAYCTRL idelayctrl_2 (
    .REFCLK(REFCLK),
    .RDY(RDY_2)
);

assign led[0] = RDY_1;
assign led[1] = RDY_2;

wire OUTPUTS[7:0];

// ISERDES reset generator
wire i_rstdiv;

// First ISERDES/IDELAY bank
wire DDLY_1;

IDELAYE2 #
(
.IDELAY_TYPE    ("FIXED"),
.DELAY_SRC      ("IDATAIN"),
.IDELAY_VALUE   (5'd31)
)
idelay_1
(
.C              (SYSCLK),
.CE             (1'b1),
.LD             (1'b1),
.INC            (1'b1),
.IDATAIN        (sw[0]),
.DATAOUT        (DDLY_1)
);

ISERDESE2 #
(
.DATA_RATE          ("SDR"),
.DATA_WIDTH         (3'd4),
.INTERFACE_TYPE     ("NETWORKING"),
.NUM_CE             (2)
)
iserdes_1
(
.CLK        (SYSCLK),
.CLKB       (SYSCLK),
.CLKDIV     (CLKDIV),
.CE1        (1'b1),
.CE2        (1'b1),
.RST        (RST),
.DDLY       (DDLY_1),
.Q1         (led[5]),
.Q2         (led[4]),
.Q3         (led[3]),
.Q4         (led[2]),
);

// Second ISERDES/IDELAY bank
wire DDLY_2;

IDELAYE2 #
(
.IDELAY_TYPE    ("FIXED"),
.DELAY_SRC      ("IDATAIN"),
.IDELAY_VALUE   (5'd31)
)
idelay_2
(
.C              (SYSCLK),
.CE             (1'b1),
.LD             (1'b1),
.INC            (1'b1),
.IDATAIN        (sw[1]),
.DATAOUT        (DDLY_2)
);

ISERDESE2 #
(
.DATA_RATE          ("SDR"),
.DATA_WIDTH         (3'd4),
.INTERFACE_TYPE     ("NETWORKING"),
.NUM_CE             (2)
)
iserdes_2
(
.CLK        (SYSCLK),
.CLKB       (SYSCLK),
.CLKDIV     (CLKDIV),
.CE1        (1'b1),
.CE2        (1'b1),
.RST        (RST),
.DDLY       (DDLY_2),
.Q1         (led[9]),
.Q2         (led[8]),
.Q3         (led[7]),
.Q4         (led[6]),
);

endmodule
