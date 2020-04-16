# Input clock
#create_clock -period 10 clk100_ibuf -waveform {0.000 5.000}

# Input clock BUFG
create_clock -period 10 main_clkin -waveform {0.000 5.000}

# PLL feedback loop
create_clock -period 10 builder_mmcm_fb -waveform {0.000 5.000}

# PLL CLKOUT0
create_clock -period 16.666 main_clkout0 -waveform {0.000 8.333}

# BUFG CLKOUT0
create_clock -period 16.666 sys_clk -waveform {0.000 8.333}

# PLL CLKOUT1
create_clock -period 4.166 main_clkout1 -waveform {0.000 2.083}

# BUFG CLKOUT1
create_clock -period 4.166 sys4x_clk -waveform {0.000 2.083}

# PLL CLKOUT3
create_clock -period 4.166 main_clkout3 -waveform {1.041 3.124}


set_clock_groups -exclusive -group {main_clkin} -group {main_clkout0 sys_clk} -group {main_clkout1 main_clkout3 sys4x_clk}
