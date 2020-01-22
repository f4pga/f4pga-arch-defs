module top (
    input  wire clk,

    input  wire rx,
    output wire tx,

    input  wire [15:0] sw,
    output wire [15:0] led
);
    RAM32X1S #(
        .INIT(32'b00000000_00000000_00000000_00000010)
    ) ram7 (
        .WCLK   (clk),
        .A4     (sw[4]),
        .A3     (sw[3]),
        .A2     (sw[2]),
        .A1     (sw[1]),
        .A0     (sw[0]),
        .O      (led[7]),
        .D      (sw[7]),
        .WE     (sw[15])
    );

    RAM32X1S #(
        .INIT(32'b00000000_00000000_00000000_00000010)
    ) ram6 (
        .WCLK   (clk),
        .A4     (sw[4]),
        .A3     (sw[3]),
        .A2     (sw[2]),
        .A1     (sw[1]),
        .A0     (sw[0]),
        .O      (led[6]),
        .D      (sw[8]),
        .WE     (sw[15])
    );

    RAM32X1S #(
        .INIT(32'b00000000_00000000_00000000_00000010)
    ) ram5 (
        .WCLK   (clk),
        .A4     (sw[4]),
        .A3     (sw[3]),
        .A2     (sw[2]),
        .A1     (sw[1]),
        .A0     (sw[0]),
        .O      (led[5]),
        .D      (sw[9]),
        .WE     (sw[15])
    );

    RAM32X1S #(
        .INIT(32'b00000000_00000000_00000000_00000010)
    ) ram4 (
        .WCLK   (clk),
        .A4     (sw[4]),
        .A3     (sw[3]),
        .A2     (sw[2]),
        .A1     (sw[1]),
        .A0     (sw[0]),
        .O      (led[4]),
        .D      (sw[10]),
        .WE     (sw[15])
    );
    RAM32X1S #(
        .INIT(32'b00000000_00000000_00000000_00000010)
    ) ram3 (
        .WCLK   (clk),
        .A4     (sw[4]),
        .A3     (sw[3]),
        .A2     (sw[2]),
        .A1     (sw[1]),
        .A0     (sw[0]),
        .O      (led[3]),
        .D      (sw[14]),
        .WE     (sw[15])
    );

    RAM32X1S #(
        .INIT(32'b00000000_00000000_00000000_00000010)
    ) ram2 (
        .WCLK   (clk),
        .A4     (sw[4]),
        .A3     (sw[3]),
        .A2     (sw[2]),
        .A1     (sw[1]),
        .A0     (sw[0]),
        .O      (led[2]),
        .D      (sw[13]),
        .WE     (sw[15])
    );

    RAM32X1S #(
        .INIT(32'b00000000_00000000_00000000_00000010)
    ) ram1 (
        .WCLK   (clk),
        .A4     (sw[4]),
        .A3     (sw[3]),
        .A2     (sw[2]),
        .A1     (sw[1]),
        .A0     (sw[0]),
        .O      (led[1]),
        .D      (sw[12]),
        .WE     (sw[15])
    );

    RAM32X1S #(
        .INIT(32'b00000000_00000000_00000000_00000010)
    ) ram0 (
        .WCLK   (clk),
        .A4     (sw[4]),
        .A3     (sw[3]),
        .A2     (sw[2]),
        .A1     (sw[1]),
        .A0     (sw[0]),
        .O      (led[0]),
        .D      (sw[11]),
        .WE     (sw[15])
    );


    assign led[15:8] = { 8{&sw[15:5]} };
    assign tx = rx;

endmodule
