module processing_unit
(
// Closk & reset
input  wire CLK,
input  wire RST,

// Data input
input  wire         I_STB,
input  wire [31:0]  I_DAT,

// Data output
output wire         O_STB,
output wire [31:0]  O_DAT
);

// ============================================================================

wire [15:0] i_dat_a = I_DAT[15: 0];
wire [15:0] i_dat_b = I_DAT[31:16];

reg         o_stb;
reg  [31:0] o_dat;

always @(posedge CLK)
    o_dat <= i_dat_a * i_dat_b;

always @(posedge CLK or posedge RST)
    if (RST) o_stb <= 1'd0;
    else     o_stb <= I_STB;

assign O_STB = o_stb;
assign O_DAT = o_dat;

// ============================================================================

endmodule

