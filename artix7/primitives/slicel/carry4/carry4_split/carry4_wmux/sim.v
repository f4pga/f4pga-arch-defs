/* 
 * Generated with mux_gen.py, run 'make' in the following to regenerate in this directory;
 * %s
 */

`include "../../../../../../vpr/muxes/logic/mux2/sim.v"

(* blackbox *) (* CLASS="mux" *)
module CARRY4_{W}MUX(CI, DI, S, O);

	input wire CI;
	input wire DI;

	input wire S;

	output wire O;

	MUX2 mux (
		.I0(CI),
		.I1(DI),
		.S0(S),
		.O(O)
	);
endmodule
