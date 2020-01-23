module top (
    input  wire clk,

    input  wire rx,
    output wire tx,

    input  wire [15:0] sw,
    output wire [15:0] led
);
    RAM32X1D #(
        .INIT(32'b00000000_00000000_00000000_00000010)
    ) ram3 (
        .WCLK   (clk),
        .A4     (sw[4]),
        .A3     (sw[3]),
        .A2     (sw[2]),
        .A1     (sw[1]),
        .A0     (sw[0]),
        .DPRA4  (sw[10]),
        .DPRA3  (sw[9]),
        .DPRA2  (sw[8]),
        .DPRA1  (sw[7]),
        .DPRA0  (sw[6]),
        .SPO    (led[0]),
        .DPO    (led[1]),
        .D      (sw[13]),
        .WE     (sw[15])
    );

    RAM32X1D #(
        .INIT(32'b00000000_00000000_00000000_00000010)
    ) ram4 (
        .WCLK   (clk),
        .A4     (sw[4]),
        .A3     (sw[3]),
        .A2     (sw[2]),
        .A1     (sw[1]),
        .A0     (sw[0]),
        .DPRA4  (sw[10]),
        .DPRA3  (sw[9]),
        .DPRA2  (sw[8]),
        .DPRA1  (sw[7]),
        .DPRA0  (sw[6]),
        .SPO    (led[2]),
        .DPO    (led[3]),
        .D      (sw[12]),
        .WE     (sw[15])
    );

    assign led[15:4] = sw[15:4];
    assign tx = rx;

endmodule
