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
set_property PACKAGE_PIN R4 [get_ports {clk}]

set_property PACKAGE_PIN T14 [get_ports {led[0]}]
set_property PACKAGE_PIN T15 [get_ports {led[1]}]
set_property PACKAGE_PIN T16 [get_ports {led[2]}]
set_property PACKAGE_PIN U16 [get_ports {led[3]}]
set_property PACKAGE_PIN V15 [get_ports {led[4]}]
set_property PACKAGE_PIN W16 [get_ports {led[5]}]
set_property PACKAGE_PIN W15 [get_ports {led[6]}]
set_property PACKAGE_PIN Y13 [get_ports {led[7]}]

set_property PACKAGE_PIN E22 [get_ports {sw[0]}]
set_property PACKAGE_PIN F21 [get_ports {sw[1]}]
set_property PACKAGE_PIN G21 [get_ports {sw[2]}]
set_property PACKAGE_PIN G22 [get_ports {sw[3]}]
set_property PACKAGE_PIN H17 [get_ports {sw[4]}]
set_property PACKAGE_PIN J16 [get_ports {sw[5]}]
set_property PACKAGE_PIN K13 [get_ports {sw[6]}]
set_property PACKAGE_PIN M17 [get_ports {sw[7]}]

set_property PACKAGE_PIN AA19 [get_ports {tx}]
set_property PACKAGE_PIN V18  [get_ports {rx}]

create_clock -period 10.0 clk
