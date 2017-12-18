/* 
 * Generated with mux_gen.py, run the following to regenerate in this directory;
 * ../../../../../../utils/mux_gen.py --outdir . '--name-mux' 'CARRY4_{W}MUX' '--width' '2' '--split-inputs' '--subckt' 'MUXCY'
 */

`include "../../../../../../vpr/muxes/logic/mux2/sim.v"

module CARRY4_{W}MUX(I0, I1, S, O);

	input wire I0;
	input wire I1;

	input wire S;

	output wire O;

	MUX2 mux (
		.I0(I0),
		.I1(I1),
		.S0(S),
		.O(O)
	);
endmodule
