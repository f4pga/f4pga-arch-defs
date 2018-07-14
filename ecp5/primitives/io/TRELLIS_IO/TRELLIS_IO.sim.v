`default_nettype none
module TRELLIS_IO(
	inout B,
	input I,
	input T,
	output O
);
	parameter DIR = "INPUT";

	generate
		if (DIR == "INPUT") begin
			assign B = 1'bz;
			assign O = B;
		end else if (DIR == "OUTPUT") begin
			assign B = T ? 1'bz : I;
			assign O = 1'bx;
		end else if (DIR == "INOUT") begin
			assign B = T ? 1'bz : I;
			assign O = B;
		end else begin
			ERROR_UNKNOWN_IO_MODE error();
		end
	endgenerate

endmodule
