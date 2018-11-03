module top (
	input  clk,
	input [15:0] in,
	output [1:0] out
);
    RAM128X1S #(
        .INIT(128'b10)
    ) ram0(
        .WCLK(clk),
        .A6(in[6]),
        .A5(in[5]),
        .A4(in[4]),
        .A3(in[3]),
        .A2(in[2]),
        .A1(in[1]),
        .A0(in[0]),
        .O(out[0]),
        .D(in[13]),
        .WE(in[15])
    );

    RAM128X1S #(
        .INIT(128'b100)
    ) ram1(
        .WCLK(clk),
        .A6(in[6]),
        .A5(in[5]),
        .A4(in[4]),
        .A3(in[3]),
        .A2(in[2]),
        .A1(in[1]),
        .A0(in[0]),
        .O(out[1]),
        .D(in[14]),
        .WE(in[15])
    );
endmodule
