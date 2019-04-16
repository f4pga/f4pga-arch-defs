/** FIXME: This is probably wrong */
(* blackbox *) (* CLASS="flipflop" *)
module LDCE_ZINI (Q, G, GE, D, CLR);
	output reg [0:0] Q;

	input wire [0:0] G;
	input wire [0:0] GE;
	input wire [0:0] D;
	input wire [0:0] CLR;

	parameter [0:0] ZINI = 1'b0;
	parameter [0:0] IS_C_INVERTED = 1'b0;
	parameter [0:0] IS_D_INVERTED = 1'b0;
	parameter [0:0] IS_CLR_INVERTED = 1'b0;

	initial Q <= !ZINI;
	generate case ({|IS_C_INVERTED, |IS_CLR_INVERTED})
		2'b00: always @(posedge G, posedge CLR) if ( CLR) Q <= 1'b0; else if (GE) Q <= D ^ IS_D_INVERTED;
		2'b01: always @(posedge G, negedge CLR) if (!CLR) Q <= 1'b0; else if (GE) Q <= D ^ IS_D_INVERTED;
		2'b10: always @(negedge G, posedge CLR) if ( CLR) Q <= 1'b0; else if (GE) Q <= D ^ IS_D_INVERTED;
		2'b11: always @(negedge G, negedge CLR) if (!CLR) Q <= 1'b0; else if (GE) Q <= D ^ IS_D_INVERTED;
	endcase endgenerate
endmodule
