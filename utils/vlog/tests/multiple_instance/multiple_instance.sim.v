`include "../fig41-full-adder/adder.sim.v"
module multiple_instance (a, b, cin, cout, sum);
	localparam DATA_WIDTH = 64;

	input wire [DATA_WIDTH-1:0] a;
	input wire [DATA_WIDTH-1:0] b;
	input wire [DATA_WIDTH-1:0] cin;
	output wire [DATA_WIDTH-1:0] cout;
	output wire [DATA_WIDTH-1:0] sum;

	genvar i;
	for(i=0; i<DATA_WIDTH; i=i+1) begin:gentest
		ADDER comb (.a(a[i]), .b(b[i]), .cin(cin[i]), .cout(cout[i]), .sum(sum[i]));
	end

endmodule
