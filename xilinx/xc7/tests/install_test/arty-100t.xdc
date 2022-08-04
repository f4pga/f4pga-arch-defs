# Pin IOSTANDARDs
set_property IOSTANDARD LVCMOS33 [get_ports clk]

set_property IOSTANDARD LVCMOS25 [get_ports {led[0]}]
set_property IOSTANDARD LVCMOS25 [get_ports {led[1]}]
set_property IOSTANDARD LVCMOS25 [get_ports {led[2]}]
set_property IOSTANDARD LVCMOS25 [get_ports {led[3]}]
set_property IOSTANDARD LVCMOS25 [get_ports {led[4]}]
set_property IOSTANDARD LVCMOS25 [get_ports {led[5]}]
set_property IOSTANDARD LVCMOS25 [get_ports {led[6]}]
set_property IOSTANDARD LVCMOS25 [get_ports {led[7]}]

set_property IOSTANDARD LVCMOS12 [get_ports {sw[0]}]
set_property IOSTANDARD LVCMOS12 [get_ports {sw[1]}]
set_property IOSTANDARD LVCMOS12 [get_ports {sw[2]}]
set_property IOSTANDARD LVCMOS12 [get_ports {sw[3]}]
set_property IOSTANDARD LVCMOS12 [get_ports {sw[4]}]
set_property IOSTANDARD LVCMOS12 [get_ports {sw[5]}]
set_property IOSTANDARD LVCMOS12 [get_ports {sw[6]}]
set_property IOSTANDARD LVCMOS12 [get_ports {sw[7]}]

set_property IOSTANDARD LVCMOS12 [get_ports {tx}]
set_property IOSTANDARD LVCMOS12 [get_ports {rx}]

# Pin Locations
set_property PACKAGE_PIN E3 [get_ports {clk}]

set_property PACKAGE_PIN F6  [get_ports {led[0]}]
set_property PACKAGE_PIN J4  [get_ports {led[1]}]
set_property PACKAGE_PIN J2  [get_ports {led[2]}]
set_property PACKAGE_PIN H6  [get_ports {led[3]}]
set_property PACKAGE_PIN H5  [get_ports {led[4]}]
set_property PACKAGE_PIN J5  [get_ports {led[5]}]
set_property PACKAGE_PIN T9  [get_ports {led[6]}]
set_property PACKAGE_PIN T10 [get_ports {led[7]}]

set_property PACKAGE_PIN A8  [get_ports {sw[0]}]
set_property PACKAGE_PIN C11 [get_ports {sw[1]}]
set_property PACKAGE_PIN C10 [get_ports {sw[2]}]
set_property PACKAGE_PIN A10 [get_ports {sw[3]}]
set_property PACKAGE_PIN D9  [get_ports {sw[4]}]
set_property PACKAGE_PIN C9  [get_ports {sw[5]}]
set_property PACKAGE_PIN B9  [get_ports {sw[6]}]
set_property PACKAGE_PIN B8  [get_ports {sw[7]}]

set_property PACKAGE_PIN D10 [get_ports {tx}]
set_property PACKAGE_PIN A9  [get_ports {rx}]

create_clock -period 10.0 clk
