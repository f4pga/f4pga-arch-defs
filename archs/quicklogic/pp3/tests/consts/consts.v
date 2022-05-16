module top(
  input  wire [1:0] I,
  output wire O
);

  LUT4 #(.INIT(0)) a_lut_with_consts (
    .I0(I[0]),
    .I1(I[1]),
    .I2(1'b0),
    .I3(1'b1),
    .O(O)
  );

endmodule
