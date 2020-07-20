# Input clock 100 MHz
create_clock -period 10 clk100_ibuf -waveform {0.000 5.000}

# PLL CLKOUT0 60 MHz
create_clock -period 16.666 crg_clkout0 -waveform {0.000 8.333}

# BUFG CLKOUT0 60 MHz
create_clock -period 16.666 crg_clkout_buf0 -waveform {0.000 8.333}

# PLL CLKOUT1 240 MHz
create_clock -period 4.166 crg_clkout1  -waveform {0.000 2.083}

# BUFG CLKOUT1 240 MHz
create_clock -period 4.166 crg_clkout_buf1 -waveform {0.000 2.083}

# PLL CLKOUT2 240 MHz
create_clock -period 4.166 crg_clkout2 -waveform {1.041 3.124}

# BUFG CLKOUT2 240 MHz
create_clock -period 4.166 crg_clkout_buf2 -waveform {1.041 3.124}

# PLL CLKOUT3 200 MHz
create_clock -period 5 crg_clkout3 -waveform {0.000 2.500}

# BUFG CLKOUT3 200 MHz
create_clock -period 5 crg_clkout_buf3 -waveform {0.000 2.500}

# PLL CLKOUT4 25 MHz
create_clock -period 40 crg_clkout4 -waveform {0.000 20.000}

# BUFG CLKOUT4 25 MHz
create_clock -period 40 crg_clkout_buf4 -waveform {0.000 20.000}

