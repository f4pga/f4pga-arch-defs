module top(
    input  wire [1:0] sw,
    output wire [3:0] led
);
  assign led = {sw, sw};
endmodule
