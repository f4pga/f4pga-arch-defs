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

# Write the design in JSON format.
write_json $::env(OUT_JSON)
# Write the design in Verilog format.
write_verilog $::env(OUT_SYNTH_V)
