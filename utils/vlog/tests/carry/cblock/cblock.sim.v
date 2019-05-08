`default_nettype none

(* blackbox *)
module CBLOCK (
	I,
	O,
	CIN,
	COUT
);
	input wire [3:0] I;

	output wire O;

	(* carry="C" *)
	input wire CIN;
	(* carry="C" *)
	output wire COUT;

endmodule
