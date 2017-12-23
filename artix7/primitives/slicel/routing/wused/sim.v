/* 
 * Generated with mux_gen.py, run the following to regenerate in this directory;
 * ../../../../../utils/mux_gen.py --outdir . '--name-mux' '{W}CY0' '--name-inputs' 'O5,{W}X' '--width=2' '--type' 'routing'
 */

`include "../../../../../vpr/muxes/logic/mux2/sim.v"

module {W}USED(I0, O);

	input wire I0;

	parameter [0:0] S = 0;

	output wire O;

	MUX2 mux (
		.I0(I0),
		.I1(0),
		.S0(S),
		.O(O)
	);
endmodule
