`include "../fig41-full-adder/adder.sim.v"
module MULTIPLE_INSTANCE (a, b, c, d, cin, cout, sum);
	localparam DATA_WIDTH = 4;

	input wire [DATA_WIDTH-1:0] a;
	input wire [DATA_WIDTH-1:0] b;
	input wire [DATA_WIDTH-1:0] c;
	input wire [DATA_WIDTH-1:0] d;
	input wire cin;
	output wire cout;
	output wire [DATA_WIDTH*2-1:0] sum;

	wire [DATA_WIDTH-1:0] a2b;

	genvar i;
	for(i=0; i<DATA_WIDTH; i=i+1) begin
		ADDER comba (.a(a[i]), .b(b[i]), .cin(cin), .cout(a2b[i]), .sum(sum[i]));
	end

	genvar j;
	for(j=0; j<DATA_WIDTH; j=j+1) begin
		if ( j < DATA_WIDTH-1 ) begin
			ADDER combb (.a(c[j]), .b(d[j]), .cin(a2b[j]), .sum(sum[DATA_WIDTH+j]));
		end else begin
			ADDER combb (.a(c[j]), .b(d[j]), .cin(a2b[j]), .cout(cout), .sum(sum[DATA_WIDTH+j]));
		end
	end

endmodule
