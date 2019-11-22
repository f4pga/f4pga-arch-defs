module \$tribuf (A, EN, Y);

  parameter WIDTH = 0;

  input  [WIDTH-1:0] A;
  input              EN;
  output [WIDTH-1:0] Y;

  genvar i;
  generate for(i = 0; i < WIDTH; i = i + 1) begin
    \$_TBUF_ TBUF (
      .A(A[i]),
      .E(EN),
      .Y(Y[i])
    );

  end endgenerate

endmodule
