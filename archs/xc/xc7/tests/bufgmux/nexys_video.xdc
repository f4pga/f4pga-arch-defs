set_property PACKAGE_PIN R4 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
set_property PACKAGE_PIN T14 [get_ports led]
set_property IOSTANDARD LVCMOS25 [get_ports led]
set_property PACKAGE_PIN E22 [get_ports sw]
set_property IOSTANDARD LVCMOS12 [get_ports sw]

create_clock -period 10.0 clk
