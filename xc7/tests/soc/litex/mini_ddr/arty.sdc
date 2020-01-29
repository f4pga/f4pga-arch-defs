create_clock -period 5 sys4x_clk__main_clkout_buf1
create_clock -period 5 sys4x_clkb__main_clkout_buf4
create_clock -period 5 sys4x_dqs_clk__main_clkout_buf2
create_clock -period 5 main_clkout_buf3__clk200_clk
create_clock -period 5 -name clkb_virtual

create_clock -period 10 clk100
create_clock -period 10 main_pll_clkin__main_clkin
create_clock -period 10 builder_pll_fb

create_clock -period 20 main_clkout0
create_clock -period 20 sys_clk__VexRiscv.IBusCachedPlugin_cache.clk__VexRiscv.clk__main_clkout_buf0
create_clock -period 5 main_clkout1
create_clock -period 5 main_clkout2
create_clock -period 5 main_clkout3

set_clock_groups -exclusive -group {main_clkout1 main_clkout2 main_clkout3 sys4x_clk__main_clkout_buf1 sys4x_clkb__main_clkout_buf4 sys4x_dqs_clk__main_clkout_buf2 main_clkout_buf3__clk200_clk clkb_virtual} -group {clk100 main_pll_clkin__main_clkin builder_pll_fb} -group {main_clkout0 sys_clk__VexRiscv.IBusCachedPlugin_cache.clk__VexRiscv.clk__main_clkout_buf0}

set_max_delay 20 -from [get_clocks {sys_clk__VexRiscv.IBusCachedPlugin_cache.clk__VexRiscv.clk__main_clkout_buf0 sys4x_dqs_clk__main_clkout_buf2 main_clkout_buf3__clk200_clk}]
set_min_delay 0.1 -from [get_clocks {sys_clk__VexRiscv.IBusCachedPlugin_cache.clk__VexRiscv.clk__main_clkout_buf0 sys4x_dqs_clk__main_clkout_buf2 main_clkout_buf3__clk200_clk}]
