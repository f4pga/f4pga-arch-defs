create_project -force -part xc7a35tcpg236-1 srl_tester synth_impl

read_verilog ../basys3_top.v
read_verilog ../lfsr8_11d.v
read_verilog ../srl_tester.v

synth_design -top top

set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property BITSTREAM.GENERAL.PERFRAMECRC YES [current_design]

source ../basys3.xdc

place_design
route_design

write_bitstream -force top_vivado.bit

