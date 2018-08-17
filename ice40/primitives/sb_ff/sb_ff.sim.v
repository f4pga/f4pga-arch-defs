// Positive Edge SiliconBlue FF Cells

module SB_DFF (output `SB_DFF_REG, input C, D);
	always @(posedge C)
		Q <= D;
endmodule

module SB_DFFE (output `SB_DFF_REG, input C, E, D);
	always @(posedge C)
		if (E)
			Q <= D;
endmodule

module SB_DFFSR (output `SB_DFF_REG, input C, R, D);
	always @(posedge C)
		if (R)
			Q <= 0;
		else
			Q <= D;
endmodule

module SB_DFFR (output `SB_DFF_REG, input C, R, D);
	always @(posedge C, posedge R)
		if (R)
			Q <= 0;
		else
			Q <= D;
endmodule

module SB_DFFSS (output `SB_DFF_REG, input C, S, D);
	always @(posedge C)
		if (S)
			Q <= 1;
		else
			Q <= D;
endmodule

module SB_DFFS (output `SB_DFF_REG, input C, S, D);
	always @(posedge C, posedge S)
		if (S)
			Q <= 1;
		else
			Q <= D;
endmodule

module SB_DFFESR (output `SB_DFF_REG, input C, E, R, D);
	always @(posedge C)
		if (E) begin
			if (R)
				Q <= 0;
			else
				Q <= D;
		end
endmodule

module SB_DFFER (output `SB_DFF_REG, input C, E, R, D);
	always @(posedge C, posedge R)
		if (R)
			Q <= 0;
		else if (E)
			Q <= D;
endmodule

module SB_DFFESS (output `SB_DFF_REG, input C, E, S, D);
	always @(posedge C)
		if (E) begin
			if (S)
				Q <= 1;
			else
				Q <= D;
		end
endmodule

module SB_DFFES (output `SB_DFF_REG, input C, E, S, D);
	always @(posedge C, posedge S)
		if (S)
			Q <= 1;
		else if (E)
			Q <= D;
endmodule

// Negative Edge SiliconBlue FF Cells

module SB_DFFN (output `SB_DFF_REG, input C, D);
	always @(negedge C)
		Q <= D;
endmodule

module SB_DFFNE (output `SB_DFF_REG, input C, E, D);
	always @(negedge C)
		if (E)
			Q <= D;
endmodule

module SB_DFFNSR (output `SB_DFF_REG, input C, R, D);
	always @(negedge C)
		if (R)
			Q <= 0;
		else
			Q <= D;
endmodule

module SB_DFFNR (output `SB_DFF_REG, input C, R, D);
	always @(negedge C, posedge R)
		if (R)
			Q <= 0;
		else
			Q <= D;
endmodule

module SB_DFFNSS (output `SB_DFF_REG, input C, S, D);
	always @(negedge C)
		if (S)
			Q <= 1;
		else
			Q <= D;
endmodule

module SB_DFFNS (output `SB_DFF_REG, input C, S, D);
	always @(negedge C, posedge S)
		if (S)
			Q <= 1;
		else
			Q <= D;
endmodule

module SB_DFFNESR (output `SB_DFF_REG, input C, E, R, D);
	always @(negedge C)
		if (E) begin
			if (R)
				Q <= 0;
			else
				Q <= D;
		end
endmodule

module SB_DFFNER (output `SB_DFF_REG, input C, E, R, D);
	always @(negedge C, posedge R)
		if (R)
			Q <= 0;
		else if (E)
			Q <= D;
endmodule

module SB_DFFNESS (output `SB_DFF_REG, input C, E, S, D);
	always @(negedge C)
		if (E) begin
			if (S)
				Q <= 1;
			else
				Q <= D;
		end
endmodule

module SB_DFFNES (output `SB_DFF_REG, input C, E, S, D);
	always @(negedge C, posedge S)
		if (S)
			Q <= 1;
		else if (E)
			Q <= D;
endmodule
