module testbench;
	reg clk;
	always #5 clk = (clk === 1'b0);

   wire     data;


	top uut (
		 .clk(clk),
		 .LED1(data)
		 );

	reg [4095:0] vcdfile;

	initial begin
		if ($value$plusargs("vcd=%s", vcdfile)) begin
			$dumpfile(vcdfile);
			$dumpvars(0, testbench);
		end
	end

	initial begin
		repeat (60) @(posedge clk);
	   $finish;
	end
endmodule
