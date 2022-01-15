# Clock
set_property LOC R4 [get_ports {IO_CLK}]
set_property IOSTANDARD LVCMOS33 [get_ports {IO_CLK}]

# Leds
set_property LOC T14 [get_ports {LED[0]}]
set_property LOC T15 [get_ports {LED[1]}]
set_property LOC T16 [get_ports {LED[2]}]
set_property LOC U16 [get_ports {LED[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[3]}]

# Reset signal
set_property LOC G4 [get_ports {IO_RST_N}]
set_property IOSTANDARD LVCMOS33 [get_ports {IO_RST_N}]

create_clock -period 10.0 IO_CLK
