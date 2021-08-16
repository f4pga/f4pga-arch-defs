# Update the CLKOUT[0-5]_PHASE and CLKOUT[0-5]_DUTY_CYCLE parameter values.
# Due to the fact that Yosys doesn't support floating parameter values
# i.e. treats them as strings, the parameter values need to be multiplied by 1000
# for the PLL registers to have correct values calculated during techmapping.
proc multiply_param { cell param_name multiplier } {
    set param_value [getparam $param_name $cell]
    if {$param_value ne ""} {
        set new_param_value [expr int(round($param_value * $multiplier))]
        setparam -set $param_name $new_param_value $cell
        puts "Updated parameter $param_name of cell $cell from $param_value to $new_param_value"
    }
}

proc update_pll_params {} {
    foreach cell [selection_to_tcl_list "t:PLLE2_ADV"] {
        multiply_param $cell "CLKFBOUT_PHASE" 1000
        for {set output 0} {$output < 6} {incr output} {
            multiply_param $cell "CLKOUT${output}_PHASE" 1000
            multiply_param $cell "CLKOUT${output}_DUTY_CYCLE" 100000
        }
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
