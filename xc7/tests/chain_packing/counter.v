module top (
	input  clk,
	output [7:0] out
);

	localparam LOG2DELAY = 8;

	reg [LOG2DELAY-1:0] counter0 = 0;
	reg [LOG2DELAY-1:0] counter1 = 0;
	reg [LOG2DELAY-1:0] counter2 = 0;
	reg [LOG2DELAY-1:0] counter3 = 0;
	reg [LOG2DELAY-1:0] counter4 = 0;
	reg [LOG2DELAY-1:0] counter5 = 0;
	reg [LOG2DELAY-1:0] counter6 = 0;
	reg [LOG2DELAY-1:0] counter7 = 0;

	always @(posedge clk) begin
		counter0 <= counter0 + 1;
		counter1 <= counter1 + 1;
		counter2 <= counter2 + 1;
		counter3 <= counter3 + 1;
		counter4 <= counter4 + 1;
		counter5 <= counter5 + 1;
		counter6 <= counter6 + 1;
		counter7 <= counter7 + 1;
	end

	assign out[0] = counter0[LOG2DELAY-1];
	assign out[1] = counter1[LOG2DELAY-1];
	assign out[2] = counter2[LOG2DELAY-1];
	assign out[3] = counter3[LOG2DELAY-1];
	assign out[4] = counter4[LOG2DELAY-1];
	assign out[5] = counter5[LOG2DELAY-1];
	assign out[6] = counter6[LOG2DELAY-1];
	assign out[7] = counter7[LOG2DELAY-1];
endmodule
