module top(
  input  wire i0,
  input  wire i1,
  input  wire s,
  output wire out
);

  MUX mux_cell (i0, i1, s, out);

endmodule
