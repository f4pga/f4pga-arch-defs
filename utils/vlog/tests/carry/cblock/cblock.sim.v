`default_nettype none

(* whitebox *)
module CBLOCK (
	I,
	O,
	CIN,
	COUT
);
	input wire [3:0] I;
	(* carry="C" *)
	input wire CIN;

	(* DELAY_MATRIX_I="30e-12 30e-12 30e-12 30e-12" *)
	(* DELAY_CONST_CIN="30e-12" *)
	output wire O;

	(* carry="C" *)
	(* DELAY_MATRIX_I="30e-12 30e-12 30e-12 30e-12" *)
	(* DELAY_CONST_CIN="30e-12" *)
	output wire COUT;

	wire [4:0] internal_sum;

	assign internal_sum = I + CIN;
	assign O = internal_sum[4];
	assign COUT = internal_sum[3];
endmodule
