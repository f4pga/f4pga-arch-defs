`include "fdpe_zini.sim.v"
`include "fdce_zini.sim.v"

(* MODES="FDPE; FDCE" *)
module FF_ASYNC(C, CE, SR, D, Q);
	(* CLOCK *)
	input wire C;
	input wire CE;
	input wire SR;

	/* FF signals */
	input wire D;
	output wire Q;

	parameter MODE = "FDPE";
 	generate
		if (MODE == "FDPE") begin
			FDPE_ZINI ff(.C(C), .CE(CE), .PRE(SR), .D(D), .Q(Q));
		end
		if (MODE == "FDCE") begin
			FDCE_ZINI ff(.C(C), .CE(CE), .CLR(SR), .D(D), .Q(Q));
		end
	endgenerate
endmodule
