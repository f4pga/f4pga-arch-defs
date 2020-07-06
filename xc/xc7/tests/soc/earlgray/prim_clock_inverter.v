module prim_clock_inverter (
	clk_i,
	scanmode_i,
	clk_no
);
	parameter HasScanMode = 1'b1;
	input clk_i;
	input scanmode_i;
	output wire clk_no;
	generate
		if (HasScanMode) begin : gen_scan
			prim_clock_mux2 i_dft_tck_mux(
				.clk0_i(~clk_i),
				.clk1_i(clk_i),
				.sel_i(scanmode_i),
				.clk_o(clk_no)
			);
		end
		else begin : gen_noscan
			wire unused_scanmode;
			assign unused_scanmode = scanmode_i;
			assign clk_no = ~clk_i;
		end
	endgenerate
endmodule
