`ifndef VPR_LATCH
`define VPR_LATCH
module VPR_LATCH (D, Q, EN);

	input wire D;
	input wire EN;

	output Q;
	reg Q;


	always @ ( D or EN )
		if (EN) begin
			Q <= D;
		end

endmodule
`endif
