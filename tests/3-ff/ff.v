// Single flip-flip test.
module top(input clk, input di, output do);
  always @( posedge clk )
    do <= di;
endmodule // top
