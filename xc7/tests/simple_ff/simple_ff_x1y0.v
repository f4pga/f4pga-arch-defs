module top(
    input clk,
	input [2:0] in,
	output out
);

  wire gclk;
  BUFG bufg(.I(clk), .O(gclk));

  FDCE #(
      .INIT(0),
  ) fdse (
      .Q(out[0]),
      .C(gclk),
      .CE(in[0]),
      .D(in[1]),
      .CLR(in[2])
  );
endmodule
