module clkgen_xil7series (
	IO_CLK,
	IO_RST_N,
	clk_sys,
	clk_48MHz,
	rst_sys_n
);
	input IO_CLK;
	input IO_RST_N;
	output clk_sys;
	output clk_48MHz;
	output rst_sys_n;
	wire locked_pll;
	wire io_clk_buf;
	wire clk_50_buf;
	wire clk_50_unbuf;
	wire clk_fb_buf;
	wire clk_fb_unbuf;
	wire clk_48_buf;
	wire clk_48_unbuf;
	BUFG io_clk_ibuf(
		.I(IO_CLK),
		.O(io_clk_buf)
	);
	PLLE2_ADV #(
		.BANDWIDTH("OPTIMIZED"),
		.COMPENSATION("ZHOLD"),
		.STARTUP_WAIT("FALSE"),
		.DIVCLK_DIVIDE(1),
		.CLKFBOUT_MULT(12),
		.CLKFBOUT_PHASE(0),
		.CLKOUT0_DIVIDE(24),
		.CLKOUT0_PHASE(0),
		.CLKOUT0_DUTY_CYCLE(500),
		.CLKOUT1_DIVIDE(25),
		.CLKOUT1_PHASE(0),
		.CLKOUT1_DUTY_CYCLE(500),
		.CLKIN1_PERIOD(10)
	) pll(
		.CLKFBOUT(clk_fb_unbuf),
		.CLKOUT0(clk_50_unbuf),
		.CLKOUT1(clk_48_unbuf),
		.CLKOUT2(),
		.CLKOUT3(),
		.CLKOUT4(),
		.CLKOUT5(),
		.CLKFBIN(clk_fb_buf),
		.CLKIN1(io_clk_buf),
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
	BUFG clk_fb_bufg(
		.I(clk_fb_unbuf),
		.O(clk_fb_buf)
	);
	BUFG clk_50_bufg(
		.I(clk_50_unbuf),
		.O(clk_50_buf)
	);
	BUFG clk_48_bufg(
		.I(clk_48_unbuf),
		.O(clk_48_buf)
	);
	assign clk_sys = clk_50_buf;
	assign clk_48MHz = clk_48_buf;
	assign rst_sys_n = locked_pll & IO_RST_N;
endmodule
