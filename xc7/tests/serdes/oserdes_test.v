`default_nettype none

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
input  wire CLKDIV,
input  wire RST,

output wire [3:0] COUNT,

// Data pin
input  wire I_DAT,
output wire O_DAT
);

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
.DATA_RATE_TQ   ((DATA_RATE == "DDR" && DATA_WIDTH == 4) ? "DDR" : "BUF"),
.TRISTATE_WIDTH ((DATA_RATE == "DDR" && DATA_WIDTH == 4) ? 4 : 1)
)
oserdes
(
.CLK    (CLK),
.CLKDIV (CLKDIV),
.RST    (ser_rst),

.OCE    (1'b1),
.D1     (0),
.D2     (0),
.D3     (1),
.D4     (1),
.D5     (1),
.D6     (1),
.D7     (0),
.D8     (0),
.OQ     (O_DAT),

.TCE    (1'b1),
.T1     (1'b0), // All 0 to keep OBUFT always on.
.T2     (1'b0),
.T3     (1'b0),
.T4     (1'b0),
.TQ     (ser_tq)
);

// ============================================================================
// OUTPUT led driven by OSERDES serial output

reg [25:0] counter;

always @(posedge CLKDIV) begin
    if (RST) counter <= 1'b0;
    else if (I_DAT) counter <= counter + 1;
    else counter <= counter;
end

assign COUNT = counter[25:21];

endmodule
