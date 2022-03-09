module top(
    input wire rx_n,
    input wire rx_p,
    output wire tx_n,
    output wire tx_p
);

wire out0, out1, ref0, ref1;

GTPE2_CHANNEL GTPE2_CHANNEL (
	.GTPRXN(rx_n),
	.GTPRXP(rx_p),
	.GTPTXN(tx_n),
	.GTPTXP(tx_p),
	.PLL0CLK(out0),
	.PLL0REFCLK(ref0),
	.PLL1CLK(out1),
	.PLL1REFCLK(ref1)
);

GTPE2_COMMON #(
	.PLL0_FBDIV(3'd5),
	.PLL0_FBDIV_45(3'd4),
	.PLL0_REFCLK_DIV(1'd1)
) GTPE2_COMMON (
	.PLL0OUTCLK(out0),
	.PLL0OUTREFCLK(ref0),
	.PLL1OUTCLK(out1),
	.PLL1OUTREFCLK(ref1)
);

endmodule
