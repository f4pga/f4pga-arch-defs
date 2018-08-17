`ifndef IO_CEN
`define IO_CEN
/* Clock enable */
(* MODES = "OFF; ON" *)
module IO_CEN (
	I,
	O,
	EN,
);
	(* CLOCK *)
	input wire I;

	input wire EN;

	(* CLOCK *)
	output wire O;

	parameter MODE = "ON";

	generate
		if (MODE == "OFF") begin
			assign O = I;
		end
		if (MODE == "ON") begin
			assign O = I & EN;
		end
	endgenerate
endmodule
`endif
