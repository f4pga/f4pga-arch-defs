`ifndef VPR_INV
`define VPR_INV

(* blackbox *)
module VPR_INV (IN, OUT);

	input wire IN;
	output wire OUT;

	assign OUT = ~IN;
endmodule
`endif
