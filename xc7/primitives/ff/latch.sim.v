`include "ldpe_zini.sim.v"
`include "ldce_zini.sim.v"

(* MODES="LDPE; LDCE" *)
module LATCH(C, CE, SR, D, Q);
	(* CLOCK *)
	input wire C;
	input wire CE;
	input wire SR;

	/* FF signals */
	input wire D;
	output wire Q;

	parameter MODE = "LDPE";
 	generate
		if (MODE == "LDPE") begin
			LDPE latch(.G(C), .GE(CE), .PRE(SR), .D(D), .Q(Q));
		end
		if (MODE == "LDCE") begin
			LDCE latch(.G(C), .GE(CE), .CLR(SR), .D(D), .Q(Q));
		end
	endgenerate
endmodule
