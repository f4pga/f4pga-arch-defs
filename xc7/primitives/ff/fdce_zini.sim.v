(* blackbox *) (* CLASS="flipflop" *)
module FDCE_ZINI (Q, C, CE, D, CLR);
	output reg Q;

	input wire C;
	input wire CE;
	input wire D;
	input wire CLR;

	parameter [0:0] ZINI = 1'b0;
	parameter [0:0] IS_C_INVERTED = 1'b0;
	parameter [0:0] IS_D_INVERTED = 1'b0;
	parameter [0:0] IS_CLR_INVERTED = 1'b0;

	initial Q <= !ZINI;
	generate case ({|IS_C_INVERTED, |IS_CLR_INVERTED})
		2'b00: always @(posedge C, posedge CLR) if ( CLR) Q <= 1'b0; else if (CE) Q <= D ^ IS_D_INVERTED;
		2'b01: always @(posedge C, negedge CLR) if (!CLR) Q <= 1'b0; else if (CE) Q <= D ^ IS_D_INVERTED;
		2'b10: always @(negedge C, posedge CLR) if ( CLR) Q <= 1'b0; else if (CE) Q <= D ^ IS_D_INVERTED;
		2'b11: always @(negedge C, negedge CLR) if (!CLR) Q <= 1'b0; else if (CE) Q <= D ^ IS_D_INVERTED;
	endcase endgenerate
endmodule
