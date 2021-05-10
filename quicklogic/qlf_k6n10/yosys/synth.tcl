yosys -import

if { [info procs ql-qlf-k6n10] == {} } { plugin -i ql-qlf }
yosys -import  ;# ingest plugin commands
# Read VPR cells library
#read_verilog -lib $::env(TECHMAP_PATH)/cells_sim.v

# Synthesize
#synth -auto-top -flatten -lut 4

if {[info exists ::env(TOP)]} {
    synth_quicklogic -family qlf_k6n10 -top $::env(TOP)
} elseif { [info exists ::env(TOP)]} {
    synth_quicklogic -family qlf_k6n10 -top $::env(TOP)
} elseif { [info exists ::env(SYNTH_OPTS)]} {
    synth_quicklogic -family qlf_k6n10 $::env(SYNTH_OPTS)
} else {
    synth_quicklogic -family qlf_k6n10
}


# Write a pre-mapped design
write_verilog $::env(OUT_SYNTH_V).premap.v

# Map to the VPR cell library
techmap -map  $::env(TECHMAP_PATH)/cells_map.v

# opt_expr -undriven makes sure all nets are driven, if only by the $undef
# net.
opt_expr -undriven
opt_clean

stat

write_json $::env(OUT_JSON)
write_verilog $::env(OUT_SYNTH_V)
