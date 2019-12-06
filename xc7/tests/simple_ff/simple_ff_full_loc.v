module top(
  input  wire clk,
	input  wire [15:0] sw,
	output wire [15:0] led,

  input  wire rx,
  output wire tx
);

  wire gclk;
  BUFG bufg(.I(clk), .O(gclk));

  (* LOC="SLICE_X29Y45" *)
  FDCE #(
      .INIT(0),
  ) fdse (
      .Q  (led[0]),
      .C  (gclk),
      .CE (sw[0]),
      .D  (sw[1]),
      .CLR(sw[2])
  );
endmodule
