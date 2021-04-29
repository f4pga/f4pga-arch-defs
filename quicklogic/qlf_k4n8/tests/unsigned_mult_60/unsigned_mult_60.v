module unsigned_mult_60 (
    out,
    a,
    b
);
  output [30:0] out;
  wire [60:0] mult_wire;
  input [30:0] a;
  input [30:0] b;

  assign mult_wire = a * b;
  assign out = mult_wire[60:30] | mult_wire[29:0];

endmodule
