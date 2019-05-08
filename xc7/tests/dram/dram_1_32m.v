module top (
	input  clk,
	input [15:0] in,
	output [7:0] out
);
    RAM32M #(
        .INIT_A(64'b10),
        .INIT_B(64'b100),
        .INIT_C(64'b1000),
        .INIT_D(64'b10000)
    ) ram0 (
        .WCLK(clk),
        .ADDRA(in[4:0]),
        .ADDRB(in[4:0]),
        .ADDRC(in[4:0]),
        .ADDRD(in[9:5]),
        .DIA(in[11:10]),
        .DIB(in[11:10]),
        .DIC(in[13:12]),
        .DID(in[15:14]),
        .DOA(out[1:0]),
        .DOB(out[3:2]),
        .DOC(out[5:4]),
        .DOD(out[7:6]),
        .WE(in[15])
    );
endmodule
