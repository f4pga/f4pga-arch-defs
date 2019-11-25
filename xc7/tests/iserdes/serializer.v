`default_nettype none

// ============================================================================

module serializer #
(
parameter DATA_WIDTH = 4,    // Serialization rate
parameter DATA_RATE = "SDR" // "SDR" or "DDR"
)
(
// Clock & reset
input  wire CLK,
input  wire RST,

// Data input
input  wire[DATA_WIDTH-1:0] I,
output wire O_DAT
);

// ============================================================================
reg  [7:0]       count;
reg  [DATA_WIDTH-1:0] sreg;
wire             sreg_ld;

always @(posedge CLK)
    if (RST)            count <= 2;
    else if (count == 0) count <= ((DATA_RATE == "DDR") ? (DATA_WIDTH/2) : DATA_WIDTH) - 1;
    else            count <= count - 1;

assign sreg_ld = (count == 0);

always @(posedge CLK)
    if (sreg_ld) sreg <= I;
    else         sreg <= sreg << ((DATA_RATE == "DDR") ? 2 : 1);

wire o_dat = sreg[DATA_WIDTH-1];

// ============================================================================
// SDR/DDR output FFs
reg o_reg;

always @(posedge CLK)
    o_reg <= o_dat;

// ============================================================================

assign O_DAT = o_reg;

endmodule
