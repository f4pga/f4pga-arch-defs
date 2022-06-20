yosys -import

plugin -i ql-iob
plugin -i ql-qlf

yosys -import

# Read VPR cells library
read_verilog -lib -specify $::env(TECHMAP_PATH)/cells_sim.v
# Read device specific cells library
read_verilog -lib -specify $::env(DEVICE_CELLS_SIM)

# Synthesize
synth_quicklogic -family pp3

# Optimize the netlist by adaptively splitting cells that fit into C_FRAG into
# smaller that can fit into F_FRAG.
set mypath [ file dirname [ file normalize [ info script ] ] ]
source "$mypath/pack.tcl"

pack
stat

# Assing parameters to IO cells basing on constraints and package pinmap
if { $::env(PCF_FILE) != "" && $::env(PINMAP_FILE) != ""} {
    quicklogic_iob $::env(PCF_FILE) $::env(PINMAP_FILE)
}

# Write a pre-mapped design
write_verilog $::env(OUT_SYNTH_V).premap.v

# Select all logic_0 and logic_1 and apply the techmap to them first. This is
# necessary for constant connection detection in the subsequent techmaps.
select -set consts t:logic_0 t:logic_1
techmap -map  $::env(TECHMAP_PATH)/cells_map.v @consts

# Map to the VPR cell library
techmap -map  $::env(TECHMAP_PATH)/cells_map.v
# Map to the device specific VPR cell library
techmap -map  $::env(DEVICE_CELLS_MAP)

# opt_expr -undriven makes sure all nets are driven, if only by the $undef
# net.
opt_expr -undriven
opt_clean
setundef -zero -params
stat

# Write output JSON, fixup cell names using an external Python script
write_json $::env(OUT_JSON).org.json
exec $::env(PYTHON3) $::env(UTILS_PATH)/yosys_fixup_cell_names.py $::env(OUT_JSON).org.json $::env(OUT_JSON)

# Read the fixed JSON back and write verilog
design -reset
read_json $::env(OUT_JSON)
write_verilog $::env(OUT_SYNTH_V)
