`default_nettype none
module LUT4(input A, B, C, D, output Z);
	parameter [15:0] INIT = 16'h0000;
	assign Z = INIT[{D, C, B, A}];
endmodule
