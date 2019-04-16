`include "fdre_zini.sim.v"
`include "fdse_zini.sim.v"

(* MODES="FDSE; FDRE" *)
module FF_SYNC(C, CE, SR, D, Q);
	(* CLOCK *)
	input wire C;
	input wire CE;
	input wire SR;

	/* FF signals */
	input wire D;
	output wire Q;

	parameter MODE = "FDSE";
 	generate
		if (MODE == "FDSE") begin
			FDSE_ZINI ff(.C(C), .CE(CE), .S(SR), .D(D), .Q(Q));
		end
		if (MODE == "FDRE") begin
			FDRE_ZINI ff(.C(C), .CE(CE), .R(SR), .D(D), .Q(Q));
		end
	endgenerate
endmodule
