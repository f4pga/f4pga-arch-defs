(* blackbox *) (* CLASS="flipflop" *)
module FDSE_ZINI (Q, C, CE, D, S);
	output reg Q;

	input wire C;
	input wire CE;
	input wire D;
	input wire S;

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
