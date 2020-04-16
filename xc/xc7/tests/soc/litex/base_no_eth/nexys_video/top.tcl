
# Create Project

create_project -force -name top -part xc7a200t-sbg484-1
set_msg_config -id {Common 17-55} -new_severity {Warning}

# Add Sources

read_verilog {/home/mkurc/Repos/litex-buildenv/third_party/litex/litex/soc/cores/cpu/vexriscv/verilog/VexRiscv.v}
read_verilog {/home/mkurc/Repos/litex-buildenv/third_party/litex/litex/boards/targets/soc_basesoc_nexys_video/gateware/top.v}

# Add EDIFs


# Add IPs


# Add constraints

read_xdc top.xdc

# Add pre-synthesis commands


# Synthesis

synth_design -directive default -top top -part xc7a200t-sbg484-1

# Synthesis report

report_timing_summary -file top_timing_synth.rpt
report_utilization -hierarchical -file top_utilization_hierarchical_synth.rpt
report_utilization -file top_utilization_synth.rpt

# Optimize design

opt_design -directive default

# Add pre-placement commands


# Placement

place_design -directive default

# Placement report

report_utilization -hierarchical -file top_utilization_hierarchical_place.rpt
report_utilization -file top_utilization_place.rpt
report_io -file top_io.rpt
report_control_sets -verbose -file top_control_sets.rpt
report_clock_utilization -file top_clock_utilization.rpt

# Add pre-routing commands


# Routing

route_design -directive default
phys_opt_design -directive default
write_checkpoint -force top_route.dcp

# Routing report

report_timing_summary -no_header -no_detailed_paths
report_route_status -file top_route_status.rpt
report_drc -file top_drc.rpt
report_timing_summary -datasheet -max_paths 10 -file top_timing.rpt
report_power -file top_power.rpt
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]

# Bitstream generation

write_bitstream -force top.bit 
write_cfgmem -force -format bin -interface spix4 -size 16 -loadbit "up 0x0 top.bit" -file top.bin

# End

quit