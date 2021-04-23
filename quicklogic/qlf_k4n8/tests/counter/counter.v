module top (
    (* clkbuf_inhibit *)
    input  wire       clk,
    output wire [3:0] led
);

  reg [7:0] cnt;
  initial cnt <= 0;

  always @(posedge clk) cnt <= cnt + 1;

  assign led = cnt[7:4];

endmodule
