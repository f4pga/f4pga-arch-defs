module top(
  input  wire [3:0] I,
  output wire O
);

  LUT4 #(.INIT(0)) the_lut (
    .I0(I[0]),
    .I1(I[1]),
    .I2(I[2]),
    .I3(I[3]),
    .O(O)
  );

endmodule
