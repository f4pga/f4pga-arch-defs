/* 
 * Generated with mux_gen.py, run the following to regenerate in this directory;
 * ../../../../../../utils/mux_gen.py --outdir . '--name-mux' 'CARRY4_{W}MUX' '--width' '2' '--split-inputs' '--subckt' 'MUXCY' '--name-inputs' 'CI,DI'
 */

`include "../../../../../../vpr/muxes/logic/mux2/sim.v"

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
