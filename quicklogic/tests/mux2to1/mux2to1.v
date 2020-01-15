module top(
  input  wire i0,
  input  wire i1,
  input  wire s,
  output wire out
);

  wire not_i0;
  NOT not_cell (.I(i0), .O(not_i0));

  MUX mux_cell (not_i0, i1, s, out);

endmodule
