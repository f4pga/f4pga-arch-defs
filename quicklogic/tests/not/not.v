module top(
  input  wire inp,
  output wire out
);

  NOT not (.I(inp), .O(out));

endmodule
