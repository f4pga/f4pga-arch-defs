module top(
    input wire clk_p_0,
    input wire clk_n_0,
    input wire clk_p_1,
    input wire clk_n_1,
    input wire test_in,
    output wire test_out
);

assign test_out = test_in;

wire gtrefclk0, gtrefclk1;

(* keep *)
GTPE2_COMMON #(
	.PLL0_FBDIV(3'd5),
	.PLL0_FBDIV_45(3'd4),
	.PLL0_REFCLK_DIV(1'd1)
) GTPE2_COMMON (
	.BGBYPASSB(1'd1),
	.BGMONITORENB(1'd1),
	.BGPDB(1'd1),
	.BGRCALOVRD(5'd31),
	.GTREFCLK0(gtrefclk0),
	.GTREFCLK1(gtrefclk1),
	.PLL0LOCKEN(1'd1),
	.PLL0PD(1'd0),
	.PLL0REFCLKSEL(1'd1),
	.PLL1PD(1'd1),
	.RCALENB(1'd1)
);

(* keep *)
IBUFDS_GTE2 IBUFDS_GTE2_0 (
	.CEB(1'd0),
	.I(clk_p_0),
	.IB(clk_n_0),
	.O(gtrefclk0)
);

(* keep *)
IBUFDS_GTE2 IBUFDS_GTE2_1 (
	.CEB(1'd0),
	.I(clk_p_1),
	.IB(clk_n_1),
	.O(gtrefclk1)
);

endmodule
