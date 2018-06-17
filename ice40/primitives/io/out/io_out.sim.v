`include "../ff1/io_ff1.sim.v"
`include "../ff2/io_ff2.sim.v"
`include "../routing/rmux2/io_rmux2.sim.v"

(* MODES = "DISABLE; DIRECT; REGISTERED; DDR" *)
module IO_OUT (
	CLK,

	D_OUT_P,
	D_OUT_N,

	D_OUT
);
	/* Input registers clock */
	(* CLOCK *)
	input wire CLK;

	input wire D_OUT_P; /* Data on positive clk edge */
	input wire D_OUT_N; /* Data on negative clk edge */

	/* Data to PACKAGE_PIN on falling clk edge */
	(* DELAY_CONST_D_OUT_P="10e-12" *)
	(* DELAY_CONST_D_OUT_N="10e-12" *)
	output wire D_OUT;

	parameter MODE = "DDR";

	/* Clock */
	wire CLK_P;
	wire CLK_N;
	assign CLK_P = CLK;
	assign CLK_N = ~CLK;

	generate
		if (MODE == "DISABLE") begin
		end
		if (MODE == "DIRECT") begin
			assign D_OUT = D_OUT_P;
		end
		if (MODE == "REGISTERED") begin
			wire do;
			IO_FF1 reg_d0(.clk(CLK_P), .D(D_OUT_P), .Q(D_OUT));
		end
		if (MODE == "DDR") begin
			wire dp;
			IO_FF1 reg_d0(.clk(CLK_P), .D(D_OUT_P), .Q(dp));
			wire dn;
			IO_FF2 reg_d1(.clk(CLK_N), .D(D_OUT_N), .Q(dn));

			/* DDR MUX */
			IO_RMUX2 ddrmux(
				.I0(dp),
				.I1(dn),
				.S0(CLK),
				.O(D_OUT));
		end
	endgenerate
endmodule
