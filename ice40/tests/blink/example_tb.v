`ifndef VCDFILE
`define VCDFILE "out.vcd"
`endif

`timescale 1 ms / 1 ps
module test;

	/* Make a regular pulsing clock. */
	reg clk = 0;
	always #1 clk = !clk;

	wire ledA;
	wire ledB;
	wire ledC;
	wire ledD;
	top uut (.clk(clk), .LED2(ledA), .LED3(ledB), .LED4(ledC), .LED5(ledD));

	initial begin
		$dumpfile(`VCDFILE);
		$dumpvars(1, clk, ledA, ledB, ledC, ledD);
		#10000;
		$dumpflush;
		$finish;
	end

endmodule // test
