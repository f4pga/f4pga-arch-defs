// D6LUT, C6LUT, B6LUT, A6LUT == W6LUT
// A fracturable 6 input LUT. Can either be;
//  - 2 * 5 input, 1 output LUT
//  - 1 * 6 input, 1 output LUT
module {N}LUT(A1, A2, A3, A4, A5, A6, O6, O5);

	input wire A1;
	input wire A2;
	input wire A3;
	input wire A4;
	input wire A5;
	input wire A6;

	(* DELAY_CONST_A1 = "1e-10" *)
	(* DELAY_CONST_A2 = "1e-10" *)
	(* DELAY_CONST_A3 = "1e-10" *)
	(* DELAY_CONST_A4 = "1e-10" *)
	(* DELAY_CONST_A5 = "1e-10" *)
	(* DELAY_CONST_A6 = "1e-10" *)
	output wire O6;

	(* DELAY_CONST_A1 = "1e-10" *)
	(* DELAY_CONST_A2 = "1e-10" *)
	(* DELAY_CONST_A3 = "1e-10" *)
	(* DELAY_CONST_A4 = "1e-10" *)
	(* DELAY_CONST_A5 = "1e-10" *)
	(* DELAY_CONST_A6 = "1e-10" *)
	output wire O5;

	parameter [63:0] INIT = 0;
	// LUT5 (upper)
	wire [15: 0] upper_s4 = A5 ?       INIT[63:48] :     INIT[47:32];
	wire [ 7: 0] upper_s3 = A4 ?   upper_s4[15: 8] : upper_s4[ 7: 0];
	wire [ 3: 0] upper_s2 = A3 ?   upper_s3[ 7: 4] : upper_s3[ 3: 0];
	wire [ 1: 0] upper_s1 = A2 ?   upper_s2[ 3: 2] : upper_s2[ 1: 0];
	wire         upper_O  = A1 ?   upper_s1[    1] : upper_s1[    0];

	// LUT5 (lower)
	wire [15: 0] lower_s4 = A5 ?       INIT[31:16] :     INIT[15: 0];
	wire [ 7: 0] lower_s3 = A4 ?   lower_s4[15: 8] : lower_s4[ 7: 0];
	wire [ 3: 0] lower_s2 = A3 ?   lower_s3[ 7: 4] : lower_s3[ 3: 0];
	wire [ 1: 0] lower_s1 = A2 ?   lower_s2[ 3: 2] : lower_s2[ 1: 0];
	wire         lower_O  = A1 ?   lower_s1[    1] : lower_s1[    0];
	assign O5 = lower_O;

	// MUXF6
	assign O6 = A6 ? upper_O : lower_O;
endmodule
