module top(
  input  wire [1:0] I,
  output wire [1:0] O
);

  assign O[0] = I[0] ^ I[1];
  assign O[1] = I[0] ^ I[1];

endmodule
