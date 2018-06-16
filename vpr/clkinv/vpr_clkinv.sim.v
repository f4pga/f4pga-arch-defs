`ifndef VPR_CLKINV
`define VPR_CLKINV
(* blackbox *) (* MODES = "ON; OFF" *)
module VPR_CLKINV (iclk, posclk, negclk);

	// "OFF" - posclk is driven
	// "ON"  - negclk is driven
	parameter MODE = "OFF";

	input wire iclk;
	output wire posclk;
	output wire negclk;

	generate
		if (MODE == "OFF") begin
			assign posclk = iclk;
		end else if (MODE == "ON") begin
			assign negclk = iclk;
		end
	endgenerate
endmodule
`endif
