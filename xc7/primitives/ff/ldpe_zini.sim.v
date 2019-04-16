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
	parameter [0:0] IS_PRE_INVERTED = 1'b0;

	initial Q <= !ZINI;
	generate case ({|IS_C_INVERTED, |IS_PRE_INVERTED})
		2'b00: always @(posedge G, posedge PRE) if ( PRE) Q <= 1'b0; else if (GE) Q <= D ^ IS_D_INVERTED;
		2'b01: always @(posedge G, negedge PRE) if (!PRE) Q <= 1'b0; else if (GE) Q <= D ^ IS_D_INVERTED;
		2'b10: always @(negedge G, posedge PRE) if ( PRE) Q <= 1'b0; else if (GE) Q <= D ^ IS_D_INVERTED;
		2'b11: always @(negedge G, negedge PRE) if (!PRE) Q <= 1'b0; else if (GE) Q <= D ^ IS_D_INVERTED;
	endcase endgenerate
endmodule
