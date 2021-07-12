module top(
  input  wire [3:0] I,
  output wire O
);

  LUT2 #(.INIT(4'b0000)) the_lut (
    .I0(I[0]),
    .I1(I[1]),
    .O(O)
  );

endmodule
