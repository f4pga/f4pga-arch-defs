module top (
	input  clk,
	input [15:0] in,
	output [1:0] out
);
    RAM128X1D #(
        .INIT(128'b10)
    ) ram0(
        .WCLK(clk),
        .A(in[6:0]),
        .DPRA(in[13:7]),
        .SPO(out[0]),
        .DPO(out[1]),
        .D(in[14]),
        .WE(in[15])
    );
endmodule
