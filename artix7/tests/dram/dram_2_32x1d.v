module top (
	input  clk,
	input [15:0] in,
	output [3:0] out
);
    RAM32X1D #(
        .INIT(32'b00000000_00000000_00000000_00000010)
    ) ram3(
        .WCLK(clk),
        .A4(in[4]),
        .A3(in[3]),
        .A2(in[2]),
        .A1(in[1]),
        .A0(in[0]),
        .DPRA4(in[10]),
        .DPRA3(in[9]),
        .DPRA2(in[8]),
        .DPRA1(in[7]),
        .DPRA0(in[6]),
        .SPO(out[0]),
        .DPO(out[1]),
        .D(in[13]),
        .WE(in[15])
    );

    RAM32X1D #(
        .INIT(32'b00000000_00000000_00000000_00000010)
    ) ram4(
        .WCLK(clk),
        .A4(in[4]),
        .A3(in[3]),
        .A2(in[2]),
        .A1(in[1]),
        .A0(in[0]),
        .DPRA4(in[10]),
        .DPRA3(in[9]),
        .DPRA2(in[8]),
        .DPRA1(in[7]),
        .DPRA0(in[6]),
        .SPO(out[2]),
        .DPO(out[3]),
        .D(in[12]),
        .WE(in[15])
    );
endmodule
