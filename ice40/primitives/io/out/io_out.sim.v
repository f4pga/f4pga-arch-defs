`include "../ff/io_ff.sim.v"
`include "../inv/io_inv.sim.v"
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

	generate
		if (MODE == "DISABLE") begin
		end
		if (MODE == "DIRECT") begin
			assign D_OUT = D_OUT_P;
		end
		if (MODE == "REGISTERED") begin
			wire do;
			IO_FF reg_d0(.clk(CLK_P), .D(D_OUT_P), .Q(D_OUT));
		end
		if (MODE == "DDR") begin
			IO_INV clk_inv(.IN(CLK_P), .OUT(CLK_N));

			wire dp;
			IO_FF reg_d0(.clk(CLK_P), .D(D_OUT_P), .Q(dp));
			wire dn;
			IO_FF reg_d1(.clk(CLK_N), .D(D_OUT_N), .Q(dn));

			/* Output mux which uses the clock to select between
			 * the output from the two different registers.
			 */
			IO_RMUX2 ddrmux(.I0(dp), .I1(dn), .S0(CLK), .O(D_OUT));
		end
	endgenerate
endmodule
