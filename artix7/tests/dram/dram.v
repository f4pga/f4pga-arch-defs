module top (
	input  clk,
	input [15:0] in,
	output [15:0] out
);
    DPRAM64 #(
        INIT(64b'00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000)
    ) ram(
        .CLK(clk),
        .A(in[5:0]),
        .O6(out[0]),
        .WA(in[13:8]),
        .DI1(in[14]),
        .WE(in[15])
    );
endmodule
