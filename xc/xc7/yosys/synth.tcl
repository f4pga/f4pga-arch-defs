yosys -import

plugin -i xdc
plugin -i fasm
plugin -i params
plugin -i selection
plugin -i sdc

# Import the commands from the plugins to the tcl interpreter
yosys -import

source [file join [file normalize [info script]] .. utils.tcl]

# -flatten is used to ensure that the output eblif has only one module.
# Some of symbiflow expects eblifs with only one module.
#
# Do not infer IOBs for targets that use a ROI.
if { $::env(USE_ROI) == "TRUE" } {
    synth_xilinx -flatten -abc9 -nosrl -noclkbuf -nodsp -noiopad -nowidelut
} else {
    # Read Yosys baseline library first.
    read_verilog -lib -specify +/xilinx/cells_sim.v
    read_verilog -lib +/xilinx/cells_xtra.v

    # Overwrite some models (e.g. IBUF with more parameters)
    read_verilog -lib $::env(TECHMAP_PATH)/iobs.v

    hierarchy -check -auto-top

    # Start flow after library reading
    synth_xilinx -flatten -abc9 -nosrl -noclkbuf -nodsp -iopad -nowidelut -run prepare:check
}

# Check that post-synthesis cells match libraries.
hierarchy -check

if { [info exists ::env(INPUT_XDC_FILE)] && $::env(INPUT_XDC_FILE) != "" } {
  read_xdc -part_json $::env(PART_JSON) $::env(INPUT_XDC_FILE)
  write_fasm -part_json $::env(PART_JSON)  $::env(OUT_FASM_EXTRA)

  # Perform clock propagation based on the information from the XDC commands
  propagate_clocks
}

update_pll_params

write_verilog $::env(OUT_SYNTH_V).premap.v

# Look for connections OSERDESE2.OQ -> OBUFDS.I. Annotate OBUFDS with a parameter
# indicating that it is connected to an OSERDESE2
select -set obufds t:OSERDESE2 %co2:+\[OQ,I\] t:OBUFDS t:OBUFTDS %u  %i
setparam -set HAS_OSERDES 1 @obufds

# Map Xilinx tech library to 7-series VPR tech library.
read_verilog -specify -lib $::env(TECHMAP_PATH)/cells_sim.v

# Convert congested CARRY4 outputs to LUTs.
techmap -map  $::env(TECHMAP_PATH)/carry_map.v
write_json $::env(OUT_JSON).carry_fixup.json
exec $::env(PYTHON3) $::env(TECHMAP_PATH)/fix_carry.py < $::env(OUT_JSON).carry_fixup.json > $::env(OUT_JSON).carry_fixup_out.json
design -push
read_json $::env(OUT_JSON).carry_fixup_out.json

techmap -map  $::env(TECHMAP_PATH)/clean_carry_map.v

# Re-read baseline libraries
read_verilog -lib -specify +/xilinx/cells_sim.v
read_verilog -lib +/xilinx/cells_xtra.v
read_verilog -specify -lib $::env(TECHMAP_PATH)/cells_sim.v
if { $::env(USE_ROI) != "TRUE" } {
    read_verilog -lib $::env(TECHMAP_PATH)/iobs.v
}

# Re-run optimization flow to absorb carry modifications
hierarchy -check -auto-top

write_ilang $::env(OUT_JSON).pre_abc9.ilang
if { $::env(USE_ROI) == "TRUE" } {
    synth_xilinx -flatten -abc9 -nosrl -noclkbuf -nodsp -noiopad -nowidelut -run map_ffs:check
} else {
    synth_xilinx -flatten -abc9 -nosrl -noclkbuf -nodsp -iopad -nowidelut -run map_ffs:check
}

write_ilang $::env(OUT_JSON).post_abc9.ilang

# Either the JSON bounce or ABC9 pass causes the CARRY4_VPR CIN/CYINIT pins
# to have 0's when unused.  As a result VPR will attempt to route a 0 to those
# ports. However this is not generally possible or desirable.
#
# $::env(TECHMAP_PATH)/cells_map.v has a simple techmap pass where these
# unused ports are removed.  In theory yosys's "rmports" would work here, but
# it does not.
chtype -map CARRY4_VPR CARRY4_FIX
techmap -map  $::env(TECHMAP_PATH)/cells_map.v

# opt_expr -undriven makes sure all nets are driven, if only by the $undef
# net.
opt_expr -undriven
opt_clean

setundef -zero -params
stat

# TODO: remove this as soon as new VTR master+wip is pushed: https://github.com/SymbiFlow/vtr-verilog-to-routing/pull/525
attrmap -remove hdlname

# Write the design in JSON format.
write_json $::env(OUT_JSON)
# Write the design in Verilog format.
write_verilog $::env(OUT_SYNTH_V)
#Write the SDC file
write_sdc $::env(OUT_SDC)
