yosys -import

plugin -i xdc
plugin -i fasm
#Import the commands from the plugins to the tcl interpreter
yosys -import

# Infer 3-state IOBUFs.
#
# First infer 3-state muxes. This converts $mux cells with "z" inputs to
# $tribuf cells. Since iopadmap requires $_TBUF_ cells to properly infer
# 3-state IOBUFs we need to map it first. Next the iopadmaps infers intermediate
# $IOBUF cells.
#
# Yosys assumes that when T=1'b1 the output is active. In Xilinx architecture
# it is the opposite. Therefore another techmap is needed that inserts an
# inverter to $IOBUF cells thus making them Xilinx's IOBUFs driven by correct
# T signals.
tribuf
techmap -map $::env(symbiflow-arch-defs_SOURCE_DIR)/xc7/techmap/tribuf.v 
iopadmap -bits -tinoutpad \$IOBUF T:O:I:IO
techmap -map $::env(symbiflow-arch-defs_SOURCE_DIR)/xc7/techmap/io_map.v

# -flatten is used to ensure that the output eblif has only one module.
# Some of symbiflow expects eblifs with only one module.
synth_xilinx -vpr -flatten -abc9 -nosrl -noclkbuf -nodsp

if { [info exists ::env(INPUT_XDC_FILE)] && $::env(INPUT_XDC_FILE) != "" } {
  read_xdc -part_json $::env(PART_JSON) $::env(INPUT_XDC_FILE)
  write_fasm -part_json $::env(PART_JSON)  $::env(OUT_FASM_EXTRA)
}

write_verilog $::env(OUT_SYNTH_V).premap.v

# Map Xilinx tech library to 7-series VPR tech library.
read_verilog -lib $::env(symbiflow-arch-defs_SOURCE_DIR)/xc7/techmap/cells_sim.v
techmap -map  $::env(symbiflow-arch-defs_SOURCE_DIR)/xc7/techmap/cells_map.v

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
