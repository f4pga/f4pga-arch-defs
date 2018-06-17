(* MODES = "DISABLE; INPUT_ONLY; OUTPUT_ONLY; TRISTATE" *)
module IO_TRI (
	OE,
	O,
	I,

	PIN_I,
	PIN_O,
	PIN_OE
);
	input O;
	input OE;
	output I;

	input PIN_I;
	output PIN_O;
	output PIN_OE;

	parameter MODE = "TRISTATE";

	generate
		if (MODE == "INPUT_ONLY") begin
			assign I = PIN_I;
		end
		if (MODE == "OUTPUT_ONLY") begin
			assign PIN_O = O;
		end
		if (MODE == "TRISTATE") begin
			assign I = PIN_I;
			assign PIN_O = O;
			assign PIN_OE = OE;
			/*
			(* blackbox *)
			TRIBUF tribuf(
				.I(I), .O(O), .OE(OE),
				.PIN_I(PIN_I),
				.PIN_O(PIN_O));
			*/
		end
	endgenerate
endmodule
