yosys -import

# Read VPR cells library
read_verilog -lib $::env(TECHMAP_PATH)/cells_sim.v

# Synthesize
synth_quicklogic -flatten

# Assing parameters to IO cells basing on constraints and package pinmap
if { $::env(PCF_FILE) != "" && $::env(PINMAP_FILE) != ""} {
    plugin -i ql-iob
    quicklogic_iob $::env(PCF_FILE) $::env(PINMAP_FILE)
}

# Write a pre-mapped design
write_verilog $::env(OUT_SYNTH_V).premap.v

# Map to the VPR cell library
techmap -map  $::env(TECHMAP_PATH)/cells_map.v

# opt_expr -undriven makes sure all nets are driven, if only by the $undef
# net.
opt_expr -undriven
opt_clean

setundef -zero -params

stat

write_json $::env(OUT_JSON)
write_verilog $::env(OUT_SYNTH_V)
