`ifndef GBDRV
`define GBDRV
/* Global network driver. */
(* blackbox *)
module GLOBAL_DRIVER (IN, OUT);
	input wire IN;
	(* DELAY_CONST_IN="10e-12" *)
	output wire OUT;

	assign OUT = IN;
endmodule
`endif
