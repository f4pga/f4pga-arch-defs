`ifndef IO_INV
`define IO_INV

(* MODES = "STRAIGHT; INVERT" *)
module IO_INV (
	I,
	O
);
	input wire I;
	output wire O;

	parameter MODE = "INVERT";

	generate
		if (MODE == "STRAIGHT") begin
			assign O = I;
		end
		if (MODE == "INVERT") begin
			assign O = ~I;
		end
	endgenerate
endmodule

`endif
