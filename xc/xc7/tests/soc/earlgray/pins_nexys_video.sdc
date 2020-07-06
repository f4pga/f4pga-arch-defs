create_clock -period 10.000 IO_CLK_BUFG -waveform {0.000 5.000}
create_clock -period 10.000 clkgen.io_clk_buf -waveform {0.000 5.000}
create_clock -period 20.000 clkgen.clk_50_buf -waveform {0.000 10.000}
create_clock -period 20.833 clkgen.clk_48_buf -waveform {0.000 10.416}
create_clock -period 10.000 clkgen.clk_fb_buf -waveform {0.000 5.000}
