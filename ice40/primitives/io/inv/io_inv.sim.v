`ifndef IO_INV
`define IO_INV

`include "../../../../vpr/inv/vpr_inv.sim.v"

module IO_INV (
	IN,
	OUT
);
	input wire IN;
	output wire OUT;

	VPR_INV inv(
		.IN(IN),
		.OUT(OUT)
	);
endmodule

`endif
