module top (
	input  clk,
	output LED
);

	reg [2:0] counter = 0;

	always @(posedge clk) begin
		counter <= counter + 1;
	end

	assign LED = counter[2];
endmodule
