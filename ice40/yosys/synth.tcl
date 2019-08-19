yosys -import

synth_ice40 -nocarry

# opt_expr -undriven makes sure all nets are driven, if only by the $undef
# net.
opt_expr -undriven
opt_clean

setundef -zero -params
write_blif -attr -cname -param $::env(OUT_EBLIF)
write_verilog $::env(OUT_SYNTH_V)
