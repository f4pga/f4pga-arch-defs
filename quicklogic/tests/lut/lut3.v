module top(
  input  wire [3:0] I,
  output wire O
);

  LUT3 #(.INIT(0)) the_lut (
    .I0(I[0]),
    .I1(I[1]),
    .I2(I[2]),
    .O(O)
  );

endmodule
