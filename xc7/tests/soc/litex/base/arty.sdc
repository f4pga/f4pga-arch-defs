create_clock -period 10 clk100 -waveform {0.000 5.000}
create_clock -period 10 soc_clk100bg -waveform {0.000 5.000}
create_clock -period 10 soc_pll_fb -waveform {0.000 5.000}
create_clock -period 4.166 sys4x_clk -waveform {0.000 2.083}
create_clock -period 4.166 sys4x_dqs_clk -waveform {1.041 3.124}
create_clock -period 16.666 soc_pll_sys -waveform {0.000 8.333}
create_clock -period 16.666 sys_clk__VexRiscv.IBusCachedPlugin_cache.clk__VexRiscv.clk__VexRiscv.dataCache_1_.clk -waveform {0.000 8.333}
create_clock -period 4.166 soc_pll_sys4x  -waveform {0.000 2.083}
create_clock -period 4.166 soc_pll_sys4x_dqs -waveform {1.041 3.124}
set_clock_groups -exclusive -group {clk100 soc_clk100bg soc_pll_fb} -group {soc_pll_sys sys_clk__VexRiscv.IBusCachedPlugin_cache.clk__VexRiscv.clk__VexRiscv.dataCache_1_.clk} -group {soc_pll_sys4x soc_pll_sys4x_dqs}
