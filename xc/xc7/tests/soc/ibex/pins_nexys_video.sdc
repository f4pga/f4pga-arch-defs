create_clock -period 10.0 clkgen.IO_CLK -waveform {0.000 5.000}
create_clock -period 10.0 clkgen.io_clk_bufg -waveform {0.000 5.000}
create_clock -period 10.0 clkgen.clk_pll_fb -waveform {0.000 5.000}
create_clock -period 40.0 clkgen.clk_50_unbuf -waveform {0.000 20.000}
create_clock -period 40.0 clkgen.clk_sys -waveform {0.000 20.000}
