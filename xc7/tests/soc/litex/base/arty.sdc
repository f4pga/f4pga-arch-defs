# Input clock 100 MHz
create_clock -period 10 clk100 -waveform {0.000 5.000}

# Input clock BUFG 100 MHz
create_clock -period 10 soc_clk100bg -waveform {0.000 5.000}

# Input eth clock transmitter 25 MHz
create_clock -period 40 eth_clocks_tx -waveform {0.000 20.000}

# Input eth clock BUFG 25 MHz
create_clock -period 40 eth_tx_clk -waveform {0.000 20.000}

# Input eth clock receiver 25 MHz
create_clock -period 40 eth_clocks_rx -waveform {0.000 20.000}

# Input eth clock BUFG 25 MHz
create_clock -period 40 eth_rx_clk -waveform {0.000 20.000}

# PLL feedback loop 100 MHz
create_clock -period 10 soc_pll_fb -waveform {0.000 5.000}

# PLL CLKOUT0 60 MHz
create_clock -period 16.666 soc_pll_sys -waveform {0.000 8.333}

# BUFG CLKOUT0 60 MHz
create_clock -period 16.666 sys_clk__VexRiscv.IBusCachedPlugin_cache.clk__VexRiscv.clk__VexRiscv.dataCache_1_.clk -waveform {0.000 8.333}

# PLL CLKOUT1 240 MHz
create_clock -period 4.166 soc_pll_sys4x  -waveform {0.000 2.083}

# BUFG CLKOUT1 240 MHz
create_clock -period 4.166 sys4x_clk -waveform {0.000 2.083}

# PLL CLKOUT2 240 MHz
create_clock -period 4.166 soc_pll_sys4x_dqs -waveform {1.041 3.124}

# BUFG CLKOUT2 240 MHz
create_clock -period 4.166 sys4x_dqs_clk -waveform {1.041 3.124}

# PLL CLKOUT3 200 MHz
create_clock -period 5 soc_pll_clk200 -waveform {0.000 2.500}

# BUFG CLKOUT3 200 MHz
create_clock -period 5 clk200_clk -waveform {0.000 2.500}

# PLL CLKOUT4 25 MHz
create_clock -period 40 soc_pll_clk100 -waveform {0.000 20.000}

# BUFG CLKOUT4 25 MHz
create_clock -period 40 eth_ref_clk -waveform {0.000 20.000}

set_clock_groups -exclusive -group {clk100 soc_clk100bg soc_pll_fb} -group {soc_pll_sys sys_clk__VexRiscv.IBusCachedPlugin_cache.clk__VexRiscv.clk__VexRiscv.dataCache_1_.clk} -group {soc_pll_sys4x soc_pll_sys4x_dqs} -group {main_clkout3 clk200_clk} -group {eth_ref_clk eth_rx_clk eth_clocks_rx eth_tx_clk eth_clocks_tx}
