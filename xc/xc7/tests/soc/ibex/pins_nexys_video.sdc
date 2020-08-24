create_clock -period 10.0 clkgen.io_clk_buf -waveform {0.000 5.000}
create_clock -period 40.0 clkgen.clk_50_unbuf -waveform {0.000 20.000}
create_clock -period 10.0 clkgen.clk_fb_unbuf -waveform {0.000 5.000}
create_clock -period 40.0 clkgen.clk_sys -waveform {0.000 20.000}
