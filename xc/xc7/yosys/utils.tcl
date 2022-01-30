# Update the CLKOUT[0-5]_PHASE and CLKOUT[0-5]_DUTY_CYCLE parameter values.
# Due to the fact that Yosys doesn't support floating parameter values
# i.e. treats them as strings, the parameter values need to be multiplied by 1000
# for the PLL registers to have correct values calculated during techmapping.
proc multiply_param { cell param_name multiplier } {
    set param_value [getparam $param_name $cell]
    if {$param_value ne ""} {
        set new_param_value [expr int(round([expr $param_value * $multiplier]))]
        setparam -set $param_name $new_param_value $cell
        puts "Updated parameter $param_name of cell $cell from $param_value to $new_param_value"
    }
}

proc update_pll_and_mmcm_params {} {
    foreach cell [selection_to_tcl_list "t:PLLE2_ADV"] {
        multiply_param $cell "CLKFBOUT_PHASE" 1000
        for {set output 0} {$output < 6} {incr output} {
            multiply_param $cell "CLKOUT${output}_PHASE" 1000
            multiply_param $cell "CLKOUT${output}_DUTY_CYCLE" 100000
        }
    }

    foreach cell [selection_to_tcl_list "t:MMCME2_ADV"] {
        multiply_param $cell "CLKFBOUT_PHASE" 1000
        for {set output 0} {$output < 7} {incr output} {
            multiply_param $cell "CLKOUT${output}_PHASE" 1000
            multiply_param $cell "CLKOUT${output}_DUTY_CYCLE" 100000
        }
        multiply_param $cell "CLKFBOUT_MULT_F" 1000
        multiply_param $cell "CLKOUT0_DIVIDE_F" 1000
    }
}

proc clean_processes {} {
    proc_clean
    proc_rmdead
    proc_prune
    proc_init
    proc_arst
    proc_mux
    proc_dlatch
    proc_dff
    proc_memwr
    proc_clean
}

proc json2eblif {out_eblif} {
    # Clean
    opt_clean

    # Designs that directly tie OPAD's to constants cannot use the dedicate
    # constant network as an artifact of the way the ROI is configured.
    # Until the ROI is removed, enable designs to selectively disable the dedicated
    # constant network.
    if { [info exists ::env(USE_LUT_CONSTANTS)] } {
	write_blif -attr -cname -param \
	    $out_eblif
    } else {
	write_blif -attr -cname -param \
	    -true VCC VCC \
	    -false GND GND \
	    -undef VCC VCC \
	    $out_eblif
    }
}

proc synth_xc7_1 {top techmap_path} {
    source [file join [file normalize [info script]] .. utils.tcl]

    # -flatten is used to ensure that the output eblif has only one module.
    # Some of symbiflow expects eblifs with only one module.
    #
    # To solve the carry chain congestion at the output, the synthesis step
    # needs to be executed two times.
    # abc9 seems to cause troubles if called multiple times in the flow, therefore
    # it gets called only at the last synthesis step
    #
    # Do not infer IOBs for targets that use a ROI.
    if { $::env(USE_ROI) == "TRUE" } {
	synth_xilinx -flatten -nosrl -noclkbuf -nodsp -noiopad -nowidelut
    } else {
	# Read Yosys baseline library first.
	read_verilog -lib -specify +/xilinx/cells_sim.v
	read_verilog -lib +/xilinx/cells_xtra.v

	# Overwrite some models (e.g. IBUF with more parameters)
	read_verilog -lib $techmap_path/iobs.v

	# TODO: This should eventually end up in upstream Yosys
	#       as models such as FD are not currently supported
	#       as being used in old FPGAs (e.g. Spartan6)
	# Read in unsupported models
	read_verilog -lib $techmap_path/retarget.v

	if { $top != "" } {
	    hierarchy -check -top $top
	} else {
	    hierarchy -check -auto-top
	}

	# Start flow after library reading
	synth_xilinx -flatten -nosrl -noclkbuf -nodsp -iopad -nowidelut -run prepare:check
    }

    # Check that post-synthesis cells match libraries.
    hierarchy -check
}

proc fixup_oserdes {} {
    # Look for connections OSERDESE2.OQ -> OBUFDS.I. Annotate OBUFDS with a parameter
    # indicating that it is connected to an OSERDESE2
    select -set obufds t:OSERDESE2 %co2:+\[OQ,I\] t:OBUFDS t:OBUFTDS %u  %i
    setparam -set HAS_OSERDES 1 @obufds
}

# Convert congested CARRY4 outputs to LUTs.
#
# This is required because VPR cannot reliably resolve SLICE[LM] output
# congestion when both O and CO outputs are used. For this reason if both O
# and CO outputs are used, the CO output is computed using a LUT.
#
# Ideally VPR would resolve the congestion in one of the following ways:
#
#  - If either O or CO are registered in a FF, then no output
#    congestion exists if the O or CO FF is packed into the same cluster.
#    The register output will used the [ABCD]Q output, and the unregistered
#    output will used the [ABCD]MUX.
#
#  - If neither the O or CO are registered in a FF, then the [ABCD]Q output
#    can still be used if the FF is placed into "transparent latch" mode.
#    VPR can express this edge, but because using a FF in "transparent latch"
#    mode requires running specific CE and SR signals connected to constants,
#    VPR cannot easily (or at all) express this packing situation.
#
#    VPR's packer in theory could be expanded to express this kind of
#    situation.
#
#                                   CLE Row
#
# +--------------------------------------------------------------------------+
# |                                                                          |
# |                                                                          |
# |                                               +---+                      |
# |                                               |    +                     |
# |                                               |     +                    |
# |                                     +-------->+ O    +                   |
# |              CO CHAIN               |         |       +                  |
# |                                     |         |       +---------------------> xMUX
# |                 ^                   |   +---->+ CO    +                  |
# |                 |                   |   |     |      +                   |
# |                 |                   |   |     |     +                    |
# |       +---------+----------+        |   |     |    +                     |
# |       |                    |        |   |     +---+                      |
# |       |     CARRY ROW      |        |   |                                |
# |  +--->+ S              O   +--------+   |       xOUTMUX                  |
# |       |                    |        |   |                                |
# |       |                    |        +   |                                |
# |  +--->+ DI             CO  +-------+o+--+                                |
# |       |      CI CHAIN      |        +   |                                |
# |       |                    |        |   |                                |
# |       +---------+----------+        |   |       xFFMUX                   |
# |                 ^                   |   |                                |
# |                 |                   |   |     +---+                      |
# |                 +                   |   |     |    +                     |
# |                                     |   +     |     +    +-----------+   |
# |                                     +--+o+--->+ O    +   |           |   |
# |                                         +     |       +  |    xFF    |   |
# |                                         |     |       +->--D----   Q +------> xQ
# |                                         |     |       +  |           |   |
# |                                         +---->+ CO   +   |           |   |
# |                                               |     +    +-----------+   |
# |                                               |    +                     |
# |                                               +---+                      |
# |                                                                          |
# |                                                                          |
# +--------------------------------------------------------------------------+
#
proc fixup_carry {out_json techmap_path utils_path} {

    techmap -map  $techmap_path/carry_map.v

    clean_processes
    write_json $out_json.carry_fixup.json

    if { [info exists ::env(PYTHON3)] } {
	set python3 $::env(PYTHON3)
    } else {
	set python3 python3
    }
    exec $python3 $utils_path/fix_xc7_carry.py < $out_json.carry_fixup.json > $out_json.carry_fixup_out.json
    design -push
    read_json $out_json.carry_fixup_out.json

    techmap -map  $techmap_path/clean_carry_map.v

    # Re-read baseline libraries
    read_verilog -lib -specify +/xilinx/cells_sim.v
    read_verilog -lib +/xilinx/cells_xtra.v
    read_verilog -specify -lib $techmap_path/cells_sim.v
    if { $::env(USE_ROI) != "TRUE" } {
	read_verilog -lib $techmap_path/iobs.v
    }

    # Re-run optimization flow to absorb carry modifications
    hierarchy -check

    write_ilang $out_json.pre_abc9.ilang
    if { $::env(USE_ROI) == "TRUE" } {
	synth_xilinx -flatten -abc9 -nosrl -noclkbuf -nodsp -noiopad -nowidelut -run map_ffs:check
    } else {
	synth_xilinx -flatten -abc9 -nosrl -noclkbuf -nodsp -iopad -nowidelut -run map_ffs:check
    }

    write_ilang $out_json.post_abc9.ilang

    # Either the JSON bounce or ABC9 pass causes the CARRY4_VPR CIN/CYINIT pins
    # to have 0's when unused.  As a result VPR will attempt to route a 0 to
    # those ports. However this is not generally possible or desirable.
    #
    # $techmap/cells_map.v has a simple techmap pass where these
    # unused ports are removed.  In theory yosys's "rmports" would work here,
    # but it does not.
    chtype -map CARRY4_VPR CARRY4_FIX
    techmap -map  $techmap_path/cells_map.v
}

proc xc7_post_proc {} {
    # opt_expr -undriven makes sure all nets are driven, if only by the $undef
    # net.
    opt_expr -undriven
    opt_clean

    setundef -zero -params
    stat

    # TODO: remove this as soon as new VTR master+wip is pushed: https://github.com/SymbiFlow/vtr-verilog-to-routing/pull/525
    attrmap -remove hdlname

    clean_processes
}
