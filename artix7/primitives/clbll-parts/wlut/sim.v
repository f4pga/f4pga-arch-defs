// D6LUT, C6LUT, B6LUT, A6LUT == W6LUT
// A fracturable 6 input LUT. Can either be;
//  - 2 * 5 input, 1 output LUT
//  - 1 * 6 input, 1 output LUT
module {W}LUT(
	input A[6:1],
	output O6, O5,
);
  parameter [63:0] INIT = 0;
  wire [31: 0] s5 = I5 ? INIT[63:32] : INIT[31: 0];
  wire [15: 0] s4 = I4 ?   s5[31:16] :   s5[15: 0];
  wire [ 7: 0] s3 = I3 ?   s4[15: 8] :   s4[ 7: 0];
  wire [ 3: 0] s2 = I2 ?   s3[ 7: 4] :   s3[ 3: 0];
  wire [ 1: 0] s1 = I1 ?   s2[ 3: 2] :   s2[ 1: 0];
  assign O = I0 ? s1[1] : s1[0];
endmodule
