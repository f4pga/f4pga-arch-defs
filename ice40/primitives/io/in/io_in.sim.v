`include "../ff1/io_ff1.sim.v"
`include "../ff2/io_ff2.sim.v"

(* MODES = "DISABLE; DIRECT; REGISTERED; DDR" *)
module IO_IN (
	CLK,

	D_IN,

	D_IN_P,
	D_IN_N
);
	/* Input registers clock */
	(* CLOCK *)
	input wire CLK;

	input wire D_IN;

	(* DELAY_CONST_D_IN="10e-12" *)
	output wire D_IN_P; /* Data on positive clk edge */
	(* DELAY_CONST_D_IN="10e-12" *)
	output wire D_IN_N; /* Data on negative clk edge */

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
			assign D_IN_P = D_IN;
		end
		if (MODE == "REGISTERED") begin
			IO_FF1 reg_d0(.clk(CLK_P), .D(D_IN), .Q(D_IN_P));
		end
		if (MODE == "DDR") begin
			IO_FF1 reg_d0(.clk(CLK_P), .D(D_IN), .Q(D_IN_P));
			IO_FF2 reg_d1(.clk(CLK_N), .D(D_IN), .Q(D_IN_N));
		end
	endgenerate
endmodule
