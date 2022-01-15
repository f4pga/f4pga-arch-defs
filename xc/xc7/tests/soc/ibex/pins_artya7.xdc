# Clock
set_property LOC E3 [get_ports {IO_CLK}]
set_property IOSTANDARD LVCMOS33 [get_ports {IO_CLK}]

# Leds
set_property LOC H5 [get_ports {LED[0]}]
set_property LOC J5 [get_ports {LED[1]}]
set_property LOC T9 [get_ports {LED[2]}]
set_property LOC T10 [get_ports {LED[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[3]}]

# Reset signal
set_property LOC C2 [get_ports {IO_RST_N}]
set_property IOSTANDARD LVCMOS33 [get_ports {IO_RST_N}]

create_clock -period 10.0 IO_CLK
