create_clock -period 10.000 IO_CLK_BUFG -waveform {0.000 5.000}
create_clock -period 10.000 clkgen.io_clk_buf -waveform {0.000 5.000}
create_clock -period 40.000 clkgen.clk_50_buf -waveform {0.000 20.000}
create_clock -period 40.166 clkgen.clk_48_buf -waveform {0.000 20.083}
create_clock -period 10.000 clkgen.clk_fb_buf -waveform {0.000 5.000}
