module top (
    input  wire clk,

    input  wire rx,
    output wire tx,

    input  wire [15:0] sw,
    output wire [15:0] led
);
    RAM256X1S #(
        .INIT(128'b10)
    ) ram0 (
        .WCLK   (clk),
        .A      (sw[7:0]),
        .O      (led[0]),
        .D      (sw[14]),
        .WE     (sw[15])
    );

    assign led[15:1] = sw[15:1];
    assign tx = rx;

endmodule
