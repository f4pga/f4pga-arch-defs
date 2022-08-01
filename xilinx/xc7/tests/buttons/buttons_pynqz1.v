module top(
    input  wire clk,
    input  wire [1:0] sw,
    input  wire [3:0] btn,
    output wire [3:0] led,
    output wire led4_b,
    output wire led4_g,
    output wire led4_r,
    output wire led5_b,
    output wire led5_g,
    output wire led5_r
);
    assign led = btn;
    assign {led4_b, led4_g, led4_r} = {3{sw[0]}};
    assign {led5_b, led5_g, led5_r} = {3{sw[1]}};
endmodule
