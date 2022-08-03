yosys -import

plugin -i xdc
plugin -i fasm
plugin -i params
plugin -i sdc
plugin -i design_introspection

# Import the commands from the plugins to the tcl interpreter
yosys -import

source [file join [file normalize [info script]] .. utils.tcl]

if { [info exists ::env(TOP)]} {
    set top $::env(TOP)
} else {
    set top ""
}

set techmap_path $::env(TECHMAP_PATH)

synth_xc7_1 $top $techmap_path



if { [info exists ::env(INPUT_XDC_FILES)] && $::env(INPUT_XDC_FILES) != "" } {
  read_xdc -part_json $::env(PART_JSON) {*}$::env(INPUT_XDC_FILES)
  write_fasm -part_json $::env(PART_JSON)  $::env(OUT_FASM_EXTRA)

  # Perform clock propagation based on the information from the XDC commands
  propagate_clocks
}

update_pll_and_mmcm_params

# Write the SDC file
#
# Note that write_sdc and the SDC plugin holds live pointers to RTLIL objects.
# If Yosys mutates those objects (e.g. destroys them), the SDC plugin will
# segfault.
write_sdc -include_propagated_clocks $::env(OUT_SDC)

write_verilog $::env(OUT_SYNTH_V).premap.v

fixup_oserdes

# Map Xilinx tech library to 7-series VPR tech library.
read_verilog -specify -lib $techmap_path/cells_sim.v

fixup_carry $::env(OUT_JSON) $techmap_path $::env(UTILS_PATH)

xc7_post_proc

# Write the design in JSON format.
write_json $::env(OUT_JSON)
# Write the design in Verilog format.
write_verilog $::env(OUT_SYNTH_V)
