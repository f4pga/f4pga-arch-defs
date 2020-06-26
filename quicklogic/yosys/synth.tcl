yosys -import

# Read VPR cells library
read_verilog -lib $::env(TECHMAP_PATH)/cells_sim.v
# Read device specific cells library
read_verilog -lib $::env(DEVICE_CELLS_SIM)

# Synthesize
synth_quicklogic 

# Assing parameters to IO cells basing on constraints and package pinmap
if { $::env(PCF_FILE) != "" && $::env(PINMAP_FILE) != ""} {
    plugin -i ql-iob
    quicklogic_iob $::env(PCF_FILE) $::env(PINMAP_FILE)
}

# Write a pre-mapped design
write_verilog $::env(OUT_SYNTH_V).premap.v

# Map to the VPR cell library
techmap -map  $::env(TECHMAP_PATH)/cells_map.v
# Map to the device specific VPR cell library
techmap -map  $::env(DEVICE_CELLS_MAP)

# Insert GMUX_PROXY after CLOCK_CELL cells
select t:CLOCK_CELL %co1:+\[O_CLK\]
clkbufmap -buf GMUX_PROXY IZ:IP
select -clear

# Map the GMUX_PROXY to GMUX with IS0=1'b1
select t:GMUX_PROXY
techmap -map  $::env(TECHMAP_PATH)/cells_map.v
select -clear

# opt_expr -undriven makes sure all nets are driven, if only by the $undef
# net.
opt_expr -undriven
opt_clean

setundef -zero -params

stat

write_json $::env(OUT_JSON)
write_verilog $::env(OUT_SYNTH_V)
