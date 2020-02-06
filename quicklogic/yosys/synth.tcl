yosys -import

# Read VPR cells library
read_verilog -lib $::env(symbiflow-arch-defs_BINARY_DIR)/quicklogic/techmap/cells_sim.v

# Synthesize
synth_quicklogic -flatten

# Map to the VPR cell library
techmap -map  $::env(symbiflow-arch-defs_SOURCE_DIR)/quicklogic/techmap/cells_map.v

write_json $::env(OUT_JSON)
write_verilog $::env(OUT_SYNTH_V)
