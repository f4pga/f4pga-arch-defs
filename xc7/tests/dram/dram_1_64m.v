module top (
	input  clk,
	input [15:0] in,
	output [3:0] out
);
    RAM64M #(
        .INIT_A(64'b10),
        .INIT_B(64'b100),
        .INIT_C(64'b1000),
        .INIT_D(64'b10000)
    ) ram0 (
        .WCLK(clk),
        .ADDRA(in[5:0]),
        .ADDRB(in[5:0]),
        .ADDRC(in[5:0]),
        .ADDRD(in[11:6]),
        .DIA(in[12]),
        .DIB(in[13]),
        .DIC(in[14]),
        .DID(in[14]),
        .DOA(out[0]),
        .DOB(out[1]),
        .DOC(out[2]),
        .DOD(out[3]),
        .WE(in[15])
    );
endmodule
