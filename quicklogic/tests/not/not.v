module top(
  input  wire inp,
  output wire out
);

  NOT not_inst (.I(inp), .O(out));

endmodule
