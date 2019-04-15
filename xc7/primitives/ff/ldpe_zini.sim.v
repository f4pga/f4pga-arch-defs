/* FIXME: This is probably wrong */
(* blackbox *) (* CLASS="flipflop" *)
module LDPE_ZINI (D, G, GE, PRE, Q);
	output reg Q;

	input wire G;
	input wire GE;
	input wire D;
	input wire PRE;

	parameter [0:0] ZINI = 1'b0;
	parameter [0:0] IS_C_INVERTED = 1'b0;
	parameter [0:0] IS_D_INVERTED = 1'b0;
	parameter [0:0] IS_S_INVERTED = 1'b0;

	initial Q <= !ZINI;
	generate case (|IS_C_INVERTED)
		1'b0: always @(posedge C) if (S == !IS_S_INVERTED) Q <= 1'b1; else if (CE) Q <= D ^ IS_D_INVERTED;
		1'b1: always @(negedge C) if (S == !IS_S_INVERTED) Q <= 1'b1; else if (CE) Q <= D ^ IS_D_INVERTED;
	endcase endgenerate
endmodule
