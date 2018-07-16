`default_nettype none
module TRELLIS_RAM16X2 (
	input DI0, DI1,
	input WAD0, WAD1, WAD2, WAD3,
	input WRE, WCK,
	input RAD0, RAD1, RAD2, RAD3,
	output DO0, DO1
);
  	parameter WCKMUX = "WCK";
	parameter WREMUX = "WRE";
	parameter INITVAL_0 = 16'h0000;
	parameter INITVAL_1 = 16'h0000;

	reg [1:0] mem[15:0];

	integer i;
	initial begin
		for (i = 0; i < 16; i = i + 1)
			mem[i] <= {INITVAL_1[i], INITVAL_0[i]};
	end

	wire muxwck = (WCKMUX == "INV") ? ~WCK : WCK;

	reg muxwre;
	always @(*)
		case (WREMUX)
			"1": muxwre = 1'b1;
			"0": muxwre = 1'b0;
			"INV": muxwre = ~WRE;
			default: muxwre = WRE;
		endcase


	always @(posedge muxwck)
		if (muxwre)
			mem[{WAD3, WAD2, WAD1, WAD0}] <= {DI1, DI0};

	assign {DO1, DO0} = mem[{RAD3, RAD2, RAD1, RAD0}];
endmodule
