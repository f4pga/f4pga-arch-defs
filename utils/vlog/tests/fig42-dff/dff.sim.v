//`include "../../../../vpr/ff/vpr_ff.sim.v"

module dff (d, clk, q);
	input wire d;
	input wire clk;
	output wire q;

	always @ ( posedge clk ) begin
		q <= d;
	end
	/*
        VPR_FF ff(
                .D(d),
                .clk(clk),
                .Q(q),
        );
	*/

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
