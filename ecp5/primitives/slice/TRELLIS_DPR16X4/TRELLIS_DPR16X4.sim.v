`default_nettype none
module TRELLIS_DPR16X4 (
	input [3:0] DI,
	input [3:0] WAD,
	input WRE, WCK,
	input [3:0] RAD,
	output [3:0] DO
);
  	parameter WCKMUX = "WCK";
	parameter WREMUX = "WRE";
	parameter [63:0] INITVAL = 64'h0000000000000000;

	reg [3:0] mem[15:0];

	integer i;
	initial begin
		for (i = 0; i < 16; i = i + 1)
			mem[i] <= INITVAL[4*i :+ 4];
	end

	wire muxwck = (WCKMUX == "INV") ? ~WCK : WCK;

	wire muxwre = (WREMUX == "1") ? 1'b1 :
							  (WREMUX == "0") ? 1'b0 :
							  (WREMUX == "INV") ? ~WRE :
							  WRE;

	always @(posedge muxwck)
		if (muxwre)
			mem[WAD] <= DI;

	assign DO = mem[RAD];
endmodule
