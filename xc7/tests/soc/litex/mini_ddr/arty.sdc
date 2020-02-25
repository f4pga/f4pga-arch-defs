create_clock -period 4.166 sys4x_clk__main_clkout_buf1 -waveform {0.000 2.083}
create_clock -period 4.166 sys4x_dqs_clk__main_clkout_buf2 -waveform {1.041 3.124}

create_clock -period 10 clk100 -waveform {0.000 5.000}
create_clock -period 10 main_pll_clkin__main_clkin -waveform {0.000 5.000}
create_clock -period 10 builder_pll_fb -waveform {0.000 5.000}

create_clock -period 16.666 main_clkout0 -waveform {0.000 8.333}
create_clock -period 16.666 sys_clk__VexRiscv.IBusCachedPlugin_cache.clk__VexRiscv.clk__main_clkout_buf0 -waveform {0.000 8.333}
create_clock -period 4.166 main_clkout1 -waveform {0.000 2.083}
create_clock -period 4.166 main_clkout2 -waveform {1.041 3.124}

set_clock_groups -exclusive -group {clk100 main_pll_clkin__main_clkin builder_pll_fb} -group {main_clkout0 sys_clk__VexRiscv.IBusCachedPlugin_cache.clk__VexRiscv.clk__main_clkout_buf0} -group {main_clkout1 main_clkout2 sys4x_dqs_clk__main_clkout_buf2 sys4x_clk__main_clkout_buf1}
