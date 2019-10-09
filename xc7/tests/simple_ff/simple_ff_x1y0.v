module top(
    input clk,
	input [2:0] in,
	output out
);

  wire gclk, hclk;
  BUFG bufg(.I(clk), .O(gclk));
  BUFH bufh(.I(gclk), .O(hclk));

  FDCE #(
      .INIT(0),
  ) fdse (
      .Q(out[0]),
      .C(hclk),
      .CE(in[0]),
      .D(in[1]),
      .CLR(in[2])
  );
endmodule
