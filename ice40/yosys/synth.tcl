yosys -import

source [file join [file normalize [info script]] .. utils.tcl]

synth_ice40 -nocarry

# opt_expr -undriven makes sure all nets are driven, if only by the $undef
# net.
opt_expr -undriven
opt_clean

# TODO: remove this as soon as new VTR master+wip is pushed: https://github.com/SymbiFlow/vtr-verilog-to-routing/pull/525
attrmap -remove hdlname

setundef -zero -params
clean_processes
write_json $::env(OUT_JSON)
write_verilog $::env(OUT_SYNTH_V)
