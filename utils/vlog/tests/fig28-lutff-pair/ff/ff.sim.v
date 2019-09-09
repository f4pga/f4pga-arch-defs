(* whitebox *)
module DFF (CLK, D, Q);

	input wire CLK;

	(* SETUP="CLK 10e-12" *)
	(* HOLD="CLK 10e-12" *)
	input wire D;

	(* CLK_TO_Q="CLK 10e-12" *)
	output reg Q;
	(* ASSOC_CLOCK="CLK" *)

	always @ ( posedge CLK ) begin
		Q <= D;
	end
endmodule
