set_property PACKAGE_PIN E3 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
set_property PACKAGE_PIN H5 [get_ports led]
set_property IOSTANDARD LVCMOS33 [get_ports led]
set_property PACKAGE_PIN A8 [get_ports sw]
set_property IOSTANDARD LVCMOS33 [get_ports sw]

create_clock -period 10.0 clk
