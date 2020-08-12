## Clock Signal
set_property -dict { PACKAGE_PIN R4    IOSTANDARD LVCMOS33 } [get_ports { IO_CLK }];
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports IO_CLK]

## Clock Domain Crossings
create_generated_clock -name clk_50_unbuf -source [get_pin clkgen/pll/CLKIN1] [get_pin clkgen/pll/CLKOUT0]
create_generated_clock -name clk_48_unbuf -source [get_pin clkgen/pll/CLKIN1] [get_pin clkgen/pll/CLKOUT1]
set_clock_groups -group clk_50_unbuf -group clk_48_unbuf -asynchronous

## LEDs
set_property -dict { PACKAGE_PIN T14   IOSTANDARD LVCMOS25 } [get_ports { LED[0] }];
set_property -dict { PACKAGE_PIN T15   IOSTANDARD LVCMOS25 } [get_ports { LED[1] }];
set_property -dict { PACKAGE_PIN T16   IOSTANDARD LVCMOS25 } [get_ports { LED[2] }];
set_property -dict { PACKAGE_PIN U16   IOSTANDARD LVCMOS25 } [get_ports { LED[3] }];

# CPU_RESET_N
set_property -dict { PACKAGE_PIN G4  IOSTANDARD LVCMOS15 } [get_ports { IO_RST_N }];
