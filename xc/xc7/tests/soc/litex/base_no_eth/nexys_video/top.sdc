# Input clock
#create_clock -period 10 clk100_ibuf -waveform {0.000 5.000}

# Input clock BUFG
create_clock -period 10 main_clkin -waveform {0.000 5.000}

# PLL feedback loop
create_clock -period 10 builder_mmcm_fb -waveform {0.000 5.000}

# PLL CLKOUT0
create_clock -period 20 main_clkout0 -waveform {0.000 10.000}

# BUFG CLKOUT0
create_clock -period 20 sys_clk -waveform {0.000 10.00}

# PLL CLKOUT1
create_clock -period 5 main_clkout1 -waveform {0.000 2.5}

# BUFG CLKOUT1
create_clock -period 5 sys4x_clk -waveform {0.000 2.5}

# PLL CLKOUT3
create_clock -period 5 main_clkout3 -waveform {0.000 2.5}


set_clock_groups -exclusive -group {main_clkin} -group {main_clkout0 sys_clk} -group {main_clkout1 main_clkout3 sys4x_clk}
