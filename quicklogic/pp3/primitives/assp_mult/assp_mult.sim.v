`timescale 1ns/10ps
(* blackbox *)
module MULT (
			Amult,
			Bmult,
			Valid_mult,
			Cmult,
			);

    input  wire  [31:0] Amult;
	input  wire  [31:0] Bmult;
	input  wire         Valid_mult;
    output wire  [63:0] Cmult;

endmodule
