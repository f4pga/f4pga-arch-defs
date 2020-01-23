module top (
    input  wire clk,

    input  wire rx,
    output wire tx,

    input  wire [15:0] sw,
    output wire [15:0] led
);
    genvar i;
    generate for (i = 0; i < 4; i = i + 1) begin:slice
        RAM32X2S #(
            .INIT_00(32'b10),
            .INIT_01(32'b100)
        ) ram (
            .WCLK   (clk),
            .A4     (sw[4]),
            .A3     (sw[3]),
            .A2     (sw[2]),
            .A1     (sw[1]),
            .A0     (sw[0]),
            .O0     (led[2*i]),
            .O1     (led[2*i+1]),
            .D0     (sw[5+2*i]),
            .D1     (sw[5+2*i+1]),
            .WE     (sw[15])
        );
    end endgenerate

    assign led[15:8] = sw[15:8];
    assign tx = rx;

endmodule


