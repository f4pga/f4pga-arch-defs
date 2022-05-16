# Input clock
create_clock -period 10 clk100_ibuf -waveform {0.000 5.000}

# Input clock BUFG
create_clock -period 10 main_pll_clkin -waveform {0.000 5.000}

# PLL BUFG feedback
create_clock -period 10 builder_pll_fb -waveform {0.000 5.000}
create_clock -period 10 builder_pll_fb_bufg -waveform {0.000 5.000}

# PLL CLKOUT0
create_clock -period 20 main_clkout0 -waveform {0.000 10.000}
# BUFG CLKOUT0
create_clock -period 20 sys_clk -waveform {0.000 10.000}

# PLL CLKOUT1
create_clock -period 5 main_clkout1 -waveform {0.000 2.500}
# BUFG CLKOUT1
create_clock -period 5 sys4x_clk -waveform {0.000 2.500}

# PLL CLKOUT2
create_clock -period 5 main_clkout2 -waveform {1.250 3.750}
# BUFG CLKOUT2
create_clock -period 5 sys4x_dqs_clk -waveform {1.250 3.750}

# PLL CLKOUT3
create_clock -period 5 main_clkout3 -waveform {0.000 2.500}
# BUFG CLKOUT3
create_clock -period 5 clk200_clk -waveform {0.000 2.500}
