module top (
    input  wire clk,

    input  wire rx,
    output wire tx,

    input  wire [15:0] sw,
    output wire [15:0] led
);
    RAM128X1S #(
        .INIT(128'b10)
    ) ram0 (
        .WCLK   (clk),
        .A6     (sw[6]),
        .A5     (sw[5]),
        .A4     (sw[4]),
        .A3     (sw[3]),
        .A2     (sw[2]),
        .A1     (sw[1]),
        .A0     (sw[0]),
        .O      (led[0]),
        .D      (sw[13]),
        .WE     (sw[15])
    );

    RAM128X1S #(
        .INIT(128'b100)
    ) ram1 (
        .WCLK   (clk),
        .A6     (sw[6]),
        .A5     (sw[5]),
        .A4     (sw[4]),
        .A3     (sw[3]),
        .A2     (sw[2]),
        .A1     (sw[1]),
        .A0     (sw[0]),
        .O      (led[1]),
        .D      (sw[14]),
        .WE     (sw[15])
    );

    assign led[15:2] = sw[15:2];
    assign tx = rx;

endmodule
