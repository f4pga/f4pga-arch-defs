module top(
  input  wire [1:0] I,
  output wire       O
);

  assign O = I[0] ^ I[1];

endmodule
