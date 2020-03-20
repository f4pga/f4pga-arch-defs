module clkgen_xil7series (
	IO_CLK,
	IO_RST_N,
	clk_sys,
	rst_sys_n
);
	input IO_CLK;
	input IO_RST_N;
	output clk_sys;
	output rst_sys_n;
	wire locked_pll;
	wire io_clk_bufg;
	wire clk_50_buf;
	wire clk_50_unbuf;
	wire clk_fb_buf;
	wire clk_fb_unbuf;
	wire clk_pll_fb;
	PLLE2_ADV #(
		.BANDWIDTH("OPTIMIZED"),
		.COMPENSATION("ZHOLD"),
		.STARTUP_WAIT("FALSE"),
		.DIVCLK_DIVIDE(1),
		.CLKFBOUT_MULT(12),
		.CLKFBOUT_PHASE(0),
		.CLKOUT0_DIVIDE(48),
		.CLKOUT0_PHASE(0)
	) pll(
		.CLKFBOUT(clk_pll_fb),
		.CLKOUT0(clk_50_unbuf),
		.CLKOUT1(),
		.CLKOUT2(),
		.CLKOUT3(),
		.CLKOUT4(),
		.CLKOUT5(),
		.CLKFBIN(clk_pll_fb),
		.CLKIN1(io_clk_bufg),
		.CLKIN2(1'b0),
		.CLKINSEL(1'b1),
		.DADDR(7'h0),
		.DCLK(1'b0),
		.DEN(1'b0),
		.DI(16'h0),
		.DO(),
		.DRDY(),
		.DWE(1'b0),
		.LOCKED(locked_pll),
		.PWRDWN(1'b0),
		.RST(1'b0)
	);
	BUFG clk_io_bufg(
		.I(IO_CLK),
		.O(io_clk_bufg)
	);
	BUFG clk_50_bufg(
		.I(clk_50_unbuf),
		.O(clk_sys)
	);

	assign rst_sys_n = (locked_pll & IO_RST_N);
endmodule
