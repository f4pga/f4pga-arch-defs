module top (
	input  clk,
	input [15:0] in,
	output [3:0] out
);
    RAM32X1S #(
        .INIT(32'b00000000_00000000_00000000_00000010)
    ) ram3 (
        .WCLK(clk),
        .A4(in[4]),
        .A3(in[3]),
        .A2(in[2]),
        .A1(in[1]),
        .A0(in[0]),
        .O(out[3]),
        .D(in[14]),
        .WE(in[15])
    );

    RAM32X1S #(
        .INIT(32'b00000000_00000000_00000000_00000010)
    ) ram4 (
        .WCLK(clk),
        .A4(in[4]),
        .A3(in[3]),
        .A2(in[2]),
        .A1(in[1]),
        .A0(in[0]),
        .O(out[2]),
        .D(in[13]),
        .WE(in[15])
    );

    RAM32X1S #(
        .INIT(32'b00000000_00000000_00000000_00000010)
    ) ram1 (
        .WCLK(clk),
        .A4(in[4]),
        .A3(in[3]),
        .A2(in[2]),
        .A1(in[1]),
        .A0(in[0]),
        .O(out[1]),
        .D(in[12]),
        .WE(in[15])
    );

    RAM32X1S #(
        .INIT(32'b00000000_00000000_00000000_00000010)
    ) ram2 (
        .WCLK(clk),
        .A4(in[4]),
        .A3(in[3]),
        .A2(in[2]),
        .A1(in[1]),
        .A0(in[0]),
        .O(out[0]),
        .D(in[11]),
        .WE(in[15])
    );
endmodule
