`default_nettype none

// ============================================================================

module iserdes_test #
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

serializer #(
    .DATA_WIDTH (DATA_WIDTH),
    .DATA_RATE  (DATA_RATE)
) serializer
(
    .CLK    (CLKDIV),
    .RST    (RST),
    .I      (INPUTS[DATA_WIDTH-1:0]),
    .O_DAT  (O_DAT)
);

// ============================================================================
// ISERDES
ISERDESE2 #
(
.DATA_RATE          (DATA_RATE),
.DATA_WIDTH         (DATA_WIDTH),
.INTERFACE_TYPE     ("NETWORKING")
)
iserdes
(
.CLK        (SYSCLK),
.CLKB       (SYSCLK),
.CLKDIV     (CLKDIV),
.CE1        (1'b1),
.CE2        (1'b1),
.RST        (i_rstdiv),
.D          (I_DAT),
.Q1         (OUTPUTS[0]),
.Q2         (OUTPUTS[1]),
.Q3         (OUTPUTS[2]),
.Q4         (OUTPUTS[3]),
.Q5         (OUTPUTS[4]),
.Q6         (OUTPUTS[5]),
.Q7         (OUTPUTS[6]),
.Q8         (OUTPUTS[7])
);

endmodule
