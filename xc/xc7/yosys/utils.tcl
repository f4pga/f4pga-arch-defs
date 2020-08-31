# Update the CLKOUT[0-5]_PHASE parameter values.
# Due to the fact that Yosys doesn't support floating parameter values
# i.e. treats them as strings, the parameter values need to be multiplied by 1000
# for the PLL registers to have correct values calculated during techmapping.
proc update_pll_params {} {
    foreach cell [selection_to_tcl_list "t:PLLE2_ADV"] {
	for {set output 0} {$output < 6} {incr output} {
	    set param_name "CLKOUT${output}_PHASE"
	    set param_value [getparam $param_name $cell]
	    if {$param_value ne ""} {
		set new_param_value [expr int(round($param_value * 1000))]
		setparam -set $param_name $new_param_value $cell
		puts "Updated parameter $param_name of cell $cell from $param_value to $new_param_value"
	    }
	}
    }
}
