create_clock -period 10 clk100 -waveform {0.000 5.000}
create_clock -period 10 soc_clk100bg -waveform {0.000 5.000}
create_clock -period 10 soc_pll_fb -waveform {0.000 5.000}
create_clock -period 3.333 sys4x_clk -waveform {0.000 1.666}
create_clock -period 3.333 sys4x_dqs_clk -waveform {0.833 2.499}
create_clock -period 13.333 soc_pll_sys -waveform {0.000 6.666}
create_clock -period 13.333 sys_clk__VexRiscv.IBusCachedPlugin_cache.clk__VexRiscv.clk__VexRiscv.dataCache_1_.clk -waveform {0.000 6.666}
create_clock -period 3.333 soc_pll_sys4x  -waveform {0.000 1.666}
create_clock -period 3.333 soc_pll_sys4x_dqs -waveform {0.833 2.499}
set_clock_groups -exclusive -group {clk100 soc_clk100bg soc_pll_fb} -group {soc_pll_sys sys_clk__VexRiscv.IBusCachedPlugin_cache.clk__VexRiscv.clk__VexRiscv.dataCache_1_.clk} -group {soc_pll_sys4x soc_pll_sys4x_dqs}
