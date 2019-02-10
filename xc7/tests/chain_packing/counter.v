module top (
	input  clk,
	output LED1,
	output LED2,
	output LED3,
	output LED4,
	//output LED5
);

	localparam LOG2DELAY = 8;

	reg [LOG2DELAY-1:0] counter0 = 0;
	reg [LOG2DELAY-1:0] counter1 = 0;
	reg [LOG2DELAY-1:0] counter2 = 0;
	reg [LOG2DELAY-1:0] counter3 = 0;
	//reg [LOG2DELAY-1:0] counter4 = 0;

	always @(posedge clk) begin
		counter0 <= counter0 + 1;
		counter1 <= counter1 + 1;
		counter2 <= counter2 + 1;
		counter3 <= counter3 + 1;
		//counter4 <= counter4 + 1;
	end

	assign LED1 = counter0[LOG2DELAY-1];
	assign LED2 = counter1[LOG2DELAY-1];
	assign LED3 = counter2[LOG2DELAY-1];
	assign LED4 = counter3[LOG2DELAY-1];
	//assign LED5 = counter4[LOG2DELAY-1];
endmodule
