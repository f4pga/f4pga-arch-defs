module top (
	input  clk,
	input [15:0] in,
	output [7:0] out
);
	genvar i;
	generate for (i = 0; i < 4; i = i + 1) begin:slice
        RAM32X2S #(
            .INIT_00(32'b10),
            .INIT_01(32'b100)
        ) ram(
            .WCLK(clk),
            .A4(in[4]),
            .A3(in[3]),
            .A2(in[2]),
            .A1(in[1]),
            .A0(in[0]),
            .O0(out[2*i]),
            .O1(out[2*i+1]),
            .D0(in[5+2*i]),
            .D1(in[5+2*i+1]),
            .WE(in[15])
        );
    end endgenerate
endmodule


