`default_nettype none

// ============================================================================

module top
(
input  wire [11:0] in,
output wire [11:0] out
);

// ============================================================================
// OBUFTDS
wire [1:0] buf_i;
wire [1:0] buf_t;

OBUFTDS obuftds_0 (
  .I(buf_i[0]),
  .T(buf_t[0]),
  .O(out[2]), // LED2
  .OB(out[3]) // LED3
);

OBUFTDS obuftds_1 (
  .I(buf_i[1]),
  .T(buf_t[1]),
  .O(out[8]), // LED8
  .OB(out[7]) // LED7
);

// ============================================================================

assign buf_i[0] = in[0];
assign buf_t[0] = in[1];
assign buf_i[1] = in[2];
assign buf_t[1] = in[3];

assign out[11: 9] = in[11: 9];
assign out[ 6: 4] = in[ 8: 6];
assign out[ 1: 0] = in[ 5: 4];

endmodule

