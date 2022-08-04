module clkgen_xil7series (
	IO_CLK,
    io_clk_bufg,
	clk_sys
);
	input IO_CLK;
	output clk_sys;
	output io_clk_bufg;
	wire locked_pll;
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

endmodule

module top (
    input wire clk,
    output wire clk1_pr1,
    output wire clk2_pr1,
    input  wire [7:0] sw,
    output wire [7:0] sw_pr1,
    output wire [7:0] led,
    input wire [7:0] led_pr1
);
    wire clk_ibuf_w;
    wire clk1_b;
    wire clk2_b;
    genvar i;
    generate
        for (i=0; i < 8; i=i+1) begin
            SYN_IBUF led_ibuf(.I(led_pr1[i]), .O(led[i]));
            SYN_OBUF sw_obuf(.I(sw[i]), .O(sw_pr1[i]));
        end
    endgenerate

    IBUF clk_ibuf(.I(clk), .O(clk_ibuf_w));
    
    clkgen_xil7series clk_gen (
        .IO_CLK(clk_ibuf_w),
        .io_clk_bufg(clk1_b),
        .clk_sys(clk2_b)
    );

    SYN_OBUF clk1_obuf(.I(clk1_b), .O(clk1_pr1));
    SYN_OBUF clk2_obuf(.I(clk2_b), .O(clk2_pr1));
endmodule
