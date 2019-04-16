`include "ff_sync.sim.v"
`include "ff_async.sim.v"
`include "latch.sim.v"

(* MODES="FF_SYNC; FF_ASYNC; LATCH" *)
module SLICE_FF(C, CE, SR, D, Q, D5, Q5);
	/* Inputs shared between FF and 5FF */
	(* CLOCK *)
	input wire C;
	input wire [7:0] CE;
	input wire [7:0] SR;

	/* FF signals */
	input wire  [3:0] D;
	output wire [3:0] Q;

	/* 5FF signals */
	input wire  [3:0] D5;
	output wire [3:0] Q5;

	parameter MODE = "FF_SYNC";
	generate
		if (MODE == "FF_SYNC") begin
			FF_SYNC  aff(.C(C), .CE(CE[0]), .SR(SR[0]), .D(D[0] ), .Q(Q[0] ));
			FF_SYNC  bff(.C(C), .CE(CE[1]), .SR(SR[1]), .D(D[1] ), .Q(Q[1] ));
			FF_SYNC  cff(.C(C), .CE(CE[2]), .SR(SR[2]), .D(D[2] ), .Q(Q[2] ));
			FF_SYNC  dff(.C(C), .CE(CE[3]), .SR(SR[3]), .D(D[3] ), .Q(Q[3] ));
			FF_SYNC a5ff(.C(C), .CE(CE[4]), .SR(SR[4]), .D(D5[0]), .Q(Q5[0]));
			FF_SYNC b5ff(.C(C), .CE(CE[5]), .SR(SR[5]), .D(D5[1]), .Q(Q5[1]));
			FF_SYNC c5ff(.C(C), .CE(CE[6]), .SR(SR[6]), .D(D5[2]), .Q(Q5[2]));
			FF_SYNC d5ff(.C(C), .CE(CE[7]), .SR(SR[7]), .D(D5[3]), .Q(Q5[3]));
		end
		if (MODE == "FF_ASYNC") begin
			FF_ASYNC  aff(.C(C), .CE(CE[0]), .SR(SR[0]), .D(D[0] ), .Q(Q[0] ));
			FF_ASYNC  bff(.C(C), .CE(CE[1]), .SR(SR[1]), .D(D[1] ), .Q(Q[1] ));
			FF_ASYNC  cff(.C(C), .CE(CE[2]), .SR(SR[2]), .D(D[2] ), .Q(Q[2] ));
			FF_ASYNC  dff(.C(C), .CE(CE[3]), .SR(SR[3]), .D(D[3] ), .Q(Q[3] ));
			FF_ASYNC a5ff(.C(C), .CE(CE[4]), .SR(SR[4]), .D(D5[0]), .Q(Q5[0]));
			FF_ASYNC b5ff(.C(C), .CE(CE[5]), .SR(SR[5]), .D(D5[1]), .Q(Q5[1]));
			FF_ASYNC c5ff(.C(C), .CE(CE[6]), .SR(SR[6]), .D(D5[2]), .Q(Q5[2]));
			FF_ASYNC d5ff(.C(C), .CE(CE[7]), .SR(SR[7]), .D(D5[3]), .Q(Q5[3]));
		end
		if (MODE == "LATCH") begin
			LATCH     aff(.C(C), .CE(CE[0]), .SR(SR[0]), .D(D[0] ), .Q(Q[0]) );
			LATCH     bff(.C(C), .CE(CE[1]), .SR(SR[1]), .D(D[1] ), .Q(Q[1]) );
			LATCH     cff(.C(C), .CE(CE[2]), .SR(SR[2]), .D(D[2] ), .Q(Q[2]) );
			LATCH     dff(.C(C), .CE(CE[3]), .SR(SR[3]), .D(D[3] ), .Q(Q[3]) );
		end
	endgenerate
endmodule
