module top(
    input clk,
	input [7:0] in,
	output [7:0] out
);
  assign out[7:1] = in[7:1];

  FDCE #(
      .INIT(0),
  ) fdse (
      .Q(out[0]),
      .C(clk),
      .CE(in[0]),
      .D(in[1]),
      .CLR(in[2])
  );
endmodule
