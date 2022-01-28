############## NET - IOSTANDARD ##################
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
#############SPI Configurate Setting##################
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design] 
set_property CONFIG_MODE SPIx4 [current_design] 
set_property BITSTREAM.CONFIG.CONFIGRATE 50 [current_design] 
set_property BITSTREAM.GENERAL.CRC Disable [current_design] 
#############clock Setting#########################
create_clock -period 20 [get_ports sys_clk]
set_property IOSTANDARD LVCMOS33 [get_ports {sys_clk}]
set_property PACKAGE_PIN P15 [get_ports {sys_clk}]
#############reset Setting##########################
set_property IOSTANDARD LVCMOS33 [get_ports {rst_n}]
set_property PACKAGE_PIN AB2 [get_ports {rst_n}]
#############LED Setting###########################
set_property PACKAGE_PIN H16 [get_ports {led[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[0]}]

set_property PACKAGE_PIN G16 [get_ports {led[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[1]}]

set_property PACKAGE_PIN K15 [get_ports {led[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[2]}]

set_property PACKAGE_PIN J15 [get_ports {led[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[3]}]