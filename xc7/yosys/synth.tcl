yosys -import

# -flatten is used to ensure that the output eblif has only one module.
# Some of symbiflow expects eblifs with only one module.
synth_xilinx -vpr -flatten -abc9 -nosrl -noclkbuf -nodsp

write_verilog $::env(OUT_SYNTH_V).premap.v

# Map Xilinx tech library to 7-series VPR tech library.
read_verilog -lib $::env(symbiflow-arch-defs_SOURCE_DIR)/xc7/techmap/cells_sim.v
techmap -map  $::env(symbiflow-arch-defs_SOURCE_DIR)/xc7/techmap/cells_map.v

# opt_expr -undriven makes sure all nets are driven, if only by the $undef
# net.
opt_expr -undriven
opt_clean

setundef -zero -params
stat

# Designs that directly tie OPAD's to constants cannot use the dedicate
# constant network as an artifact of the way the ROI is configured.
# Until the ROI is removed, enable designs to selectively disable the dedicated
# constant network.
if { [info exists ::env(USE_LUT_CONSTANTS)] } {
    write_blif -attr -cname -param \
      $::env(OUT_EBLIF)
} else {
    write_blif -attr -cname -param \
      -true VCC VCC \
      -false GND GND \
      -undef VCC VCC \
    $::env(OUT_EBLIF)
}
write_verilog $::env(OUT_SYNTH_V)
