create_project -force -part xc7a35tcpg236-1 srl_tester impl_only
set_property design_mode GateLvl [current_fileset]

add_files basys3_top.edif

link_design

set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property BITSTREAM.GENERAL.PERFRAMECRC YES [current_design]

source ../basys3.xdc

place_design
route_design

write_bitstream -force top_yosys.bit

