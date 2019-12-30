yosys -import

plugin -i xdc
plugin -i fasm
#Import the commands from the plugins to the tcl interpreter
yosys -import

# Map (actually rename) explicitly instantiated IBUFs/OBUFs in order to
# distinguish them from the inferred ones.
techmap -map $::env(TECHMAP_PATH)/iob_map.v

# -flatten is used to ensure that the output eblif has only one module.
# Some of symbiflow expects eblifs with only one module.
synth_xilinx -vpr -flatten -abc9 -nosrl -noclkbuf -nodsp -iopad

# Map inferred IBUFs/OBUFs to wires. This way ROI targets will work.
techmap -map $::env(TECHMAP_PATH)/iob_make_wires.v
# Map previously renamed IBUFs/OBUFs back to their former names.
techmap -map $::env(TECHMAP_PATH)/iob_unmap.v

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
