(* blackbox *) (* CLASS="flipflop" *)
module FDRE_ZINI (Q, C, CE, D, R);
	output reg Q;

	input wire C;
	input wire CE;
	input wire D;
	input wire R;

	parameter [0:0] ZINI = 1'b0;
	parameter [0:0] IS_C_INVERTED = 1'b0;
	parameter [0:0] IS_D_INVERTED = 1'b0;
	parameter [0:0] IS_R_INVERTED = 1'b0;

	initial Q <= !ZINI;
	generate case (|IS_C_INVERTED)
		1'b0: always @(posedge C) if (R == !IS_R_INVERTED) Q <= 1'b0; else if (CE) Q <= D ^ IS_D_INVERTED;
		1'b1: always @(negedge C) if (R == !IS_R_INVERTED) Q <= 1'b0; else if (CE) Q <= D ^ IS_D_INVERTED;
	endcase endgenerate
endmodule
