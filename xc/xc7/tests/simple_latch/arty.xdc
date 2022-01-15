# Clock
set_property LOC E3 [get_ports {clk}]
set_property IOSTANDARD LVCMOS33 [get_ports {clk}]

# Led 0-1
set_property LOC H5 [get_ports {led[0]}]
set_property LOC J5 [get_ports {led[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[1]}]

# Switches SW0-4
set_property LOC A8 [get_ports {sw[0]}]
set_property LOC C11 [get_ports {sw[1]}]
set_property LOC C10 [get_ports {sw[2]}]
set_property LOC A10 [get_ports {sw[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[3]}]
