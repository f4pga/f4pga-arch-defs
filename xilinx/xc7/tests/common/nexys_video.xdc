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

set_property IOSTANDARD LVCMOS33 [get_ports tx]
set_property IOSTANDARD LVCMOS33 [get_ports rx]

create_clock -period 10.0 clk
