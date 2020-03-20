module top (
    input  wire clk,

    input  wire rx,
    output wire tx,

    input  wire [15:0] sw,
    output wire [15:0] led
);
    RAM64X1S #(
        .INIT(64'b00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000010)
    ) ram3 (
        .WCLK   (clk),
        .A5     (sw[5]),
        .A4     (sw[4]),
        .A3     (sw[3]),
        .A2     (sw[2]),
        .A1     (sw[1]),
        .A0     (sw[0]),
        .O      (led[3]),
        .D      (sw[14]),
        .WE     (sw[15])
    );

    RAM64X1S #(
        .INIT(64'b00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000010)
    ) ram4 (
        .WCLK   (clk),
        .A5     (sw[5]),
        .A4     (sw[4]),
        .A3     (sw[3]),
        .A2     (sw[2]),
        .A1     (sw[1]),
        .A0     (sw[0]),
        .O      (led[2]),
        .D      (sw[13]),
        .WE     (sw[15])
    );

    RAM64X1S #(
        .INIT(64'b00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000010)
    ) ram1 (
        .WCLK   (clk),
        .A5     (sw[5]),
        .A4     (sw[4]),
        .A3     (sw[3]),
        .A2     (sw[2]),
        .A1     (sw[1]),
        .A0     (sw[0]),
        .O      (led[1]),
        .D      (sw[12]),
        .WE     (sw[15])
    );

    RAM64X1S #(
        .INIT(64'b00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000010)
    ) ram2 (
        .WCLK   (clk),
        .A5     (sw[5]),
        .A4     (sw[4]),
        .A3     (sw[3]),
        .A2     (sw[2]),
        .A1     (sw[1]),
        .A0     (sw[0]),
        .O      (led[0]),
        .D      (sw[11]),
        .WE     (sw[15])
    );

    assign led[15:4] = sw[15:4];
    assign tx = rx;

endmodule
