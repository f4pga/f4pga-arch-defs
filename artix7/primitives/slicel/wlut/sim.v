// FIXME: This is wrong!
// D6LUT, C6LUT, B6LUT, A6LUT == W6LUT
// A fracturable 6 input LUT. Can either be;
//  - 2 * 5 input, 1 output LUT
//  - 1 * 6 input, 1 output LUT
module {W}LUT(A1, A2, A3, A4, A5, A6, O6, O5);

	input wire A1;
	input wire A2;
	input wire A3;
	input wire A4;
	input wire A5;
	input wire A6;
	output wire O6;
	output wire O5;

	parameter [63:0] INIT = 0;
	wire [31: 0] s5 = A6 ? INIT[63:32] : INIT[31: 0];
	wire [15: 0] s4 = A5 ?   s5[31:16] :   s5[15: 0];
	wire [ 7: 0] s3 = A4 ?   s4[15: 8] :   s4[ 7: 0];
	wire [ 3: 0] s2 = A3 ?   s3[ 7: 4] :   s3[ 3: 0];
	wire [ 1: 0] s1 = A2 ?   s2[ 3: 2] :   s2[ 1: 0];
	assign O5 = A1 ? s1[1] : s1[0];
	assign O6 = A1 ? s1[1] : s1[0];
endmodule
