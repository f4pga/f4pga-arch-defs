# Input clock
create_clock -period 10 clk100 -waveform {0.000 5.000}

# Input clock BUFG
create_clock -period 10 main_pll_clkin -waveform {0.000 5.000}

# PLL feedback loop
create_clock -period 10 builder_pll_fb -waveform {0.000 5.000}

# PLL CLKOUT0
create_clock -period 16.666 main_clkout0 -waveform {0.000 8.333}

# BUFG CLKOUT0
create_clock -period 16.666 sys_clk__VexRiscv.IBusCachedPlugin_cache.clk__VexRiscv.clk -waveform {0.000 8.333}

# PLL CLKOUT1
create_clock -period 4.166 main_clkout1 -waveform {0.000 2.083}

# BUFG CLKOUT1
create_clock -period 4.166 sys4x_clk -waveform {0.000 2.083}

# PLL CLKOUT2
create_clock -period 4.166 main_clkout2 -waveform {1.041 3.124}

# BUFG CLKOUT2
create_clock -period 4.166 sys4x_dqs_clk -waveform {1.041 3.124}

# PLL CLKOUT3
create_clock -period 5 main_clkout3 -waveform {0.000 2.500}

# BUFG CLKOUT3
create_clock -period 5 clk200_clk -waveform {0.000 2.500}

set_clock_groups -exclusive -group {clk100 main_pll_clkin__main_clkin builder_pll_fb} -group {main_clkout0 sys_clk__VexRiscv.IBusCachedPlugin_cache.clk__VexRiscv.clk} -group {main_clkout1 main_clkout2 sys4x_dqs_clk sys4x_clk} -group {main_clkout3 clk200_clk}
