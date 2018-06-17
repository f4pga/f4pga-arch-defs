`include "../ff1/io_ff1.sim.v"

(* MODES = "DISABLE; DIRECT; REGISTERED" *)
module IO_OE (
	CLK,

	OE_I,
	OE_O
);
	(* CLOCK *)
	input wire CLK;

	input wire OE_I;
	(* DELAY_CONST_OE_I="10e-12" *)
	output wire OE_O;

	parameter MODE = "REGISTERED";

	generate
		if (MODE == "DISABLE") begin
		end
		if (MODE == "DIRECT") begin
			assign OE_O = OE_I;
		end
		if (MODE == "REGISTERED") begin
			IO_FF1 reg_d0(.clk(CLK), .D(OE_I), .Q(OE_O));
		end
	endgenerate
endmodule
