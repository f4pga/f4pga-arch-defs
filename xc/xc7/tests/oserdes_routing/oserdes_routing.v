module top
(
// Clocks
input  wire       clk1,
input  wire       clk2,

// Dummy data input
input  wire [1:0] i_d,
input  wire       i_t,

// OSERDES output(s)
inout  wire [1:0] out,

// Dummy outputs
output wire       o_d
);

// ============================================================================

wire clk;
wire clkdiv;

BUFG bufg1 (.I(clk1), .O(clk));
BUFG bufg2 (.I(clk2), .O(clkdiv));

// ============================================================================

reg [3:0] rst_sr;
initial rst_sr <= 4'hF;

always @(posedge clk)
    rst_sr <= rst_sr >> 1;

wire rst = rst_sr[0];

// ============================================================================

wire [1:0] iq;
wire [1:0] oq;
wire [1:0] tq;

// Dummy outputs
assign o_d = |iq;

// OBUFT is not yet supported in SymbiFlow
/*
OBUFT obuft_0 (
.I      (oq[0]),
.T      (tq[0]),
.O      (out[0])
);

OBUFT obuft_1 (
.I      (oq[1]),
.T      (tq[1]),
.O      (out[1])
);
*/

// IOBUFs
IOBUF iobuf_0 (
.O      (iq[0]),
.I      (oq[0]),
.T      (tq[0]),
.IO     (out[0])
);

IOBUF iobuf_1 (
.O      (iq[1]),
.I      (oq[1]),
.T      (tq[1]),
.IO     (out[1])
);

/*
OBUF obuf_0 (
.I      (oq[0]),
.O      (out[0])
);

OBUF obuf_1 (
.I      (oq[1]),
.O      (out[1])
);
*/

// OSERDES with inverters intended to be disabled
(* KEEP, DONT_TOUCH *)
OSERDESE2 #
(
.IS_D2_INVERTED (0),
.IS_D4_INVERTED (0),
.IS_D6_INVERTED (0),
.IS_D8_INVERTED (0),

.IS_T1_INVERTED (0),
.IS_T2_INVERTED (0),
.IS_T3_INVERTED (0),
.IS_T4_INVERTED (0),

.DATA_RATE_OQ   ("SDR"),
.DATA_RATE_TQ   ("SDR"),
.DATA_WIDTH     (8),
.TRISTATE_WIDTH (1)
)
oserdes_0
(
.CLK    (clk),
.CLKDIV (clkdiv),
.RST    (rst),

.OCE    (1'b1),

// D1-D2 routed
// D3-D4 const0
// D5-D6 const1
// D7-D8 unconnected
.D1     (i_d[0]),
.D2     (i_d[1]),
.D3     (1'b0),
.D4     (1'b0),
.D5     (1'b1),
.D6     (1'b1),
.D7     (),
.D8     (),
.OQ     (oq[0]),

.TCE    (1'b1),

// T1 - routed
// T2 - const0
// T3 - const1
// T4 - unconnected
.T1     (i_t),
.T2     (1'b0),
.T3     (1'b1),
.T4     (),
.TQ     (tq[0])
);

// OSERDES with inverters intended to be enabled
(* KEEP, DONT_TOUCH *)
OSERDESE2 #
(
.IS_D2_INVERTED (1),
.IS_D4_INVERTED (1),
.IS_D6_INVERTED (1),
.IS_D8_INVERTED (1),

.IS_T1_INVERTED (1),
.IS_T2_INVERTED (1),
.IS_T3_INVERTED (1),
.IS_T4_INVERTED (1),

.DATA_RATE_OQ   ("SDR"),
.DATA_RATE_TQ   ("SDR"),
.DATA_WIDTH     (8),
.TRISTATE_WIDTH (1)
)
oserdes_1
(
.CLK    (clk),
.CLKDIV (clkdiv),
.RST    (rst),

.OCE    (1'b1),

// D1-D2 routed
// D3-D4 const0
// D5-D6 const1
// D7-D8 unconnected
.D1     (i_d[0]),
.D2     (i_d[1]),
.D3     (1'b0),
.D4     (1'b0),
.D5     (1'b1),
.D6     (1'b1),
.D7     (),
.D8     (),
.OQ     (oq[1]),

.TCE    (1'b1),

// T1 - routed
// T2 - const0
// T3 - const1
// T4 - unconnected
.T1     (i_t),
.T2     (1'b0),
.T3     (1'b1),
.T4     (),
.TQ     (tq[1])
);

endmodule
