/*
A simplistic test for OBUFDS. Two of them are instanciated and their outpus
are connected to LEDs. Data inputs are controlled by switches.

Truth tables:

SW8  | LED3 LED2
 0   |  1    0
 1   |  0    1

SW10 | LED8 LED7
 0   |  0    1
 0   |  1    0

Couldn't use all switches and buttons at the same time as the differential
IOs use different IOSTANDARD than the single ended ones and have to be in
a separate bank.

*/
`default_nettype none

// ============================================================================

module top
(
input  wire [11:8] sw,

output wire [1:0]  diff_p,
output wire [1:0]  diff_n
);

// ============================================================================
// OBUFTDS
wire [1:0] buf_i;

OBUFDS # (
  .IOSTANDARD("DIFF_SSTL135"),
  .SLEW("FAST")
) obuftds_0 (
  .I(buf_i[0]),
  .O(diff_p[0]), // LED2
  .OB(diff_n[0]) // LED3
);

OBUFDS # (
  .IOSTANDARD("DIFF_SSTL135"),
  .SLEW("FAST")
) obuftds_1 (
  .I(buf_i[1]),
  .O(diff_p[1]), // LED8
  .OB(diff_n[1]) // LED7
);

// ============================================================================

assign buf_i[0] = sw[ 8];
assign buf_i[1] = sw[10];

endmodule

