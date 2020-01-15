yosys -import

# Read VPR cells library
read_verilog -lib $::env(symbiflow-arch-defs_BINARY_DIR)/quicklogic/techmap/cells_sim.v

# Synthesize (TODO: Use synth_quicklogic here!)
read_verilog -lib +/quicklogic/cells_sim.v
synth -top top -flatten
abc -lut 4
opt_clean

# Map to the VPR cell library
techmap -map  $::env(symbiflow-arch-defs_SOURCE_DIR)/quicklogic/techmap/cells_map.v

write_json $::env(OUT_JSON)
write_verilog $::env(OUT_SYNTH_V)
