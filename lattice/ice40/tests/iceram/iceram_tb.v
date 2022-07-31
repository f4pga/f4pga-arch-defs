`ifndef VCDFILE
`define VCDFILE "out.vcd"
`endif

module testbench;
	reg clk;
	always #5 clk = (clk === 1'b0);

	wire     data;

	top uut (
		 .clk(clk),
		 .LED1(data)
		 );

	initial begin
		$dumpfile(`VCDFILE);
		$dumpvars(1, uut);
	end

	initial begin
		repeat (6000) @(posedge clk);
		$finish;
	end
endmodule
