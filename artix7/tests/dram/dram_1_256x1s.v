module top (
	input  clk,
	input [15:0] in,
	output [0] out
);
    RAM256X1S #(
        .INIT(128'b10)
    ) ram0(
        .WCLK(clk),
        .A(in[7:0]),
        .O(out[0]),
        .D(in[14]),
        .WE(in[15])
    );
endmodule
