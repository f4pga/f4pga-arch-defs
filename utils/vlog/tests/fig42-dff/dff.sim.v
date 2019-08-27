(* whitebox *)
module DFF (D, CLK, Q);

	input wire CLK;

	(* SETUP="CLK 10e-12" *)
	(* HOLD="CLK 10e-12" *)
	(* CLK_TO_Q="CLK 10e-12" *)
	input wire D;

	(* CLK_TO_Q="CLK 10e-12" *)
	output reg Q;
	(* ASSOC_CLOCK="CLK" *)

	always @ ( posedge CLK ) begin
		Q <= D;
	end

`ifndef YOSYS
	specify
		specparam
			tplh$CLK$QP = 1.0,
			tphl$CLK$QP = 1.0,
			tplh$CLK$QN = 1.0,
			tphl$CLK$QN = 1.0,
			tsetup$D$CLK = 1.0,
			thold$D$CLK = 1.0,
			tminpwl$CLK = 1.0,
			tminpwh$CLK = 1.0;

		// PATH DELAYS
		if (flag)
			// Polarity of QP is positive referenced to D
			(posedge CLK *> (QP +: D)) = (tplh$CLK$QP, tphl$CLK$QP);
		if (flag)
			// Polarity of QN is negative referenced to D
			(posedge CLK *> (QN -: D)) = (tplh$CLK$QN, tphl$CLK$QN);

		// SETUP AND HOLD CHECKS
		$setuphold(posedge CLK &&& (flag == 1), posedge D, tsetup$D$CLK, thold$D$CLK, NOTIFIER);

		$setuphold(posedge CLK &&& (flag == 1), negedge D, tsetup$D$CLK, thold$D$CLK, NOTIFIER);

		// MINIMUM WIDTH CHECKING
		$width(negedge CLK, tminpwl$CLK, 0, NOTIFIER);
		$width(posedge CLK, tminpwh$CLK, 0, NOTIFIER);

	endspecify
`endif

endmodule
