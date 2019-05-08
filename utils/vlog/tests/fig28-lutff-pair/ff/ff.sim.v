(* blackbox *)
module DFF (CLK, D, Q);

	input wire CLK;

	(* SETUP="CLK 10-12" *)
	(* HOLD="CLK 10-12" *)
	(* CLK_TO_Q="CLK 10e-12" *)
	input wire D;

	output reg Q;

	always @ ( posedge CLK ) begin
		Q <= D;
	end
endmodule
