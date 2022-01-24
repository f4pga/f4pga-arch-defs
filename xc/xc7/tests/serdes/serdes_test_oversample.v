`default_nettype none

// ============================================================================

module serdes_test_oversample
(
input  wire SYSCLK,
input  wire SYSCLK_90,
input  wire RST,

input  wire I_DAT,

output wire [3:0] OUTPUTS
);

// ============================================================================
wire i_rstdiv;

// ISERDES reset generator
reg [3:0] rst_sr;
initial   rst_sr <= 4'hF;

always @(posedge SYSCLK)
    if (RST) rst_sr <= 4'hF;
    else     rst_sr <= rst_sr >> 1;

assign i_rstdiv = rst_sr[0];

// ============================================================================
// ISERDES
ISERDESE2 #
(
.DATA_RATE          ("DDR"),
.DATA_WIDTH         (4),
.INTERFACE_TYPE     ("OVERSAMPLE"),
.NUM_CE             (2)
)
iserdes
(
.CLK        (SYSCLK),
.CLKB       (SYSCLK),
.OCLK       (SYSCLK_90),
.OCLKB      (SYSCLK_90),
.CLKDIV     (1'b0),
.CE1        (1'b1),
.CE2        (1'b1),
.RST        (i_rstdiv),
.D          (I_DAT),
.Q1         (OUTPUTS[1]),
.Q2         (OUTPUTS[2]),
.Q3         (OUTPUTS[3]),
.Q4         (OUTPUTS[4])
);

endmodule
