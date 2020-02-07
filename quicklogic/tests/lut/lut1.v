module top(
  input  wire [3:0] I,
  output wire O
);

  LUT1 #(.INIT(2'b01)) the_lut (
    .I0(I[0]),
    .O(O)
  );

endmodule
