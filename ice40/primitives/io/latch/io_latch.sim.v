`ifndef IO_LATCH
`define IO_LATCH

`include "../../../../vpr/latch/vpr_latch.sim.v"

/* 'iCEGATE' latch found in most PIO tiles. */
(* MODES = "OFF; ON" *)
module IO_LATCH (D, EN, Q);

	input wire D;
	input wire EN;

	output Q;
	reg Q;

	parameter MODE = "ON";

	generate
		if (MODE == "OFF") begin
			assign Q = D;
		end
		if (MODE == "ON") begin
			VPR_LATCH latch(
				.D(D),
				.EN(EN),
				.Q(Q)
			);
		end
	endgenerate
endmodule
`endif
