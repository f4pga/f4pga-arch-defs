yosys -import

plugin -i xdc
plugin -i fasm

# Import the commands from the plugins to the tcl interpreter
yosys -import

# -flatten is used to ensure that the output eblif has only one module.
# Some of symbiflow expects eblifs with only one module.
#
# Do not infer IOBs for targets that use a ROI.
if { $::env(USE_ROI) == "TRUE" } {
    synth_xilinx -vpr -flatten -abc9 -nosrl -noclkbuf -nodsp
} else {
    # Read Yosys baseline library first.
    read_verilog -lib -D_EXPLICIT_CARRY +/xilinx/cells_sim.v
    read_verilog -lib +/xilinx/cells_xtra.v

    # Overwrite some models (e.g. IBUF with more parameters)
    read_verilog -lib $::env(TECHMAP_PATH)/iobs.v

    hierarchy -check -auto-top

    # Start flow after library reading
    synth_xilinx -vpr -flatten -abc9 -nosrl -noclkbuf -nodsp -iopad -run prepare:check
}
if { [info exists ::env(INPUT_XDC_FILE)] && $::env(INPUT_XDC_FILE) != "" } {
  read_xdc -part_json $::env(PART_JSON) $::env(INPUT_XDC_FILE)
  write_fasm -part_json $::env(PART_JSON)  $::env(OUT_FASM_EXTRA)
}

write_verilog $::env(OUT_SYNTH_V).premap.v

# Map Xilinx tech library to 7-series VPR tech library.
read_verilog -lib $::env(TECHMAP_PATH)/cells_sim.v
techmap -map  $::env(TECHMAP_PATH)/cells_map.v

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
