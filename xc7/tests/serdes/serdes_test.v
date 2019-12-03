`default_nettype none

// ============================================================================

module serdes_test #
(
parameter DATA_WIDTH = 8,
parameter DATA_RATE = "DDR"
)
(
input  wire SYSCLK,
input  wire CLKDIV,
input  wire RST,

input  wire I_DAT,
output wire O_DAT,
output wire T_DAT,

input  wire [7:0] INPUTS,
output wire [7:0] OUTPUTS
);

// ============================================================================
// CLKDIV generation using a BUFR
wire i_rstdiv;

// ISERDES reset generator
reg [3:0] rst_sr;
initial   rst_sr <= 4'hF;

always @(posedge CLKDIV)
    if (RST) rst_sr <= 4'hF;
    else     rst_sr <= rst_sr >> 1;

assign i_rstdiv = rst_sr[0];

// OSERDES
OSERDESE2 #(
.DATA_RATE_OQ   (DATA_RATE),
.DATA_WIDTH     (DATA_WIDTH),
.DATA_RATE_TQ   ((DATA_RATE == "DDR" && DATA_WIDTH == 4) ? "DDR" : "BUF"),
.TRISTATE_WIDTH ((DATA_RATE == "DDR" && DATA_WIDTH == 4) ? 4 : 1)
)
oserdes
(
.CLK    (SYSCLK),
.CLKDIV (CLKDIV),
.RST    (i_rstdiv),

.OCE    (1'b1),
.D1     (INPUTS[0]),
.D2     (INPUTS[1]),
.D3     (INPUTS[2]),
.D4     (INPUTS[3]),
.D5     (INPUTS[4]),
.D6     (INPUTS[5]),
.D7     (INPUTS[6]),
.D8     (INPUTS[7]),
.OQ     (O_DAT),

.TCE    (1'b1),
.T1     (1'b0), // All 0 to keep OBUFT always on.
.T2     (1'b0),
.T3     (1'b0),
.T4     (1'b0),
.TQ     (T_DAT)
);

wire DDLY;

// IDELAY
IDELAYE2 #
(
.IDELAY_TYPE    ("FIXED"),
.DELAY_SRC      ("IDATAIN"),
.IDELAY_VALUE   (5'd5)
)
idelay
(
.IDATAIN        (I_DAT),
.DATAOUT        (DDLY),
);

// ============================================================================
// ISERDES
ISERDESE2 #
(
.DATA_RATE          (DATA_RATE),
.DATA_WIDTH         (DATA_WIDTH),
.INTERFACE_TYPE     ("NETWORKING"),
.NUM_CE             (2)
)
iserdes
(
.CLK        (SYSCLK),
.CLKB       (SYSCLK),
.CLKDIV     (CLKDIV),
.CE1        (1'b1),
.CE2        (1'b1),
.RST        (i_rstdiv),
.DDLY       (DDLY),
.Q1         (OUTPUTS[7]),
.Q2         (OUTPUTS[6]),
.Q3         (OUTPUTS[5]),
.Q4         (OUTPUTS[4]),
.Q5         (OUTPUTS[3]),
.Q6         (OUTPUTS[2]),
.Q7         (OUTPUTS[1]),
.Q8         (OUTPUTS[0])
);

endmodule
