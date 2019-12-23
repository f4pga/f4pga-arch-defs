create_clock -period 5 sys4x_clk__main_clkout_buf1
create_clock -period 5 sys4x_clkb__main_clkout_buf4
create_clock -period 5 sys4x_dqs_clk__main_clkout_buf2
create_clock -period 5 main_clkout_buf3__clk200_clk

create_clock -period 10 clk100
create_clock -period 10 main_pll_clkin__main_clkin

create_clock -period 20 main_clkout0
create_clock -period 5 main_clkout1
create_clock -period 5 main_clkout2
create_clock -period 5 main_clkout3
