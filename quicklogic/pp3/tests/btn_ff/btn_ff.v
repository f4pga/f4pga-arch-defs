module top(
  input  wire clk,
  input  wire d,
  output reg  q
);

  always @(posedge clk)
      q <= d;

endmodule
