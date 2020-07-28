
proc max {a b} {
    if {$a > $b} {
        return $a
    } else {
        return $b
    }
}

proc min {a b} {
    if {$a < $b} {
        return $a
    } else {
        return $b
    }
}

# Returns the required number of C_FRAGs to fit the design
proc get_used_c_frag {} {
    set used_c_frag [get_count -cells t:mux8x0 t:LUT4 t:logic_cell_macro]
    set used_t_frag [get_count -cells t:mux4x0 t:LUT2 t:LUT3]

    set used_c_frag_for_t_frag [expr int(ceil($used_t_frag  / 2.0))]
    return [max $used_c_frag $used_c_frag_for_t_frag]
}

# Returns the required number of F_FRAGs to fit the design
proc get_used_f_frag {} {
    return [get_count -cells t:inv t:mux2x0 t:LUT1 t:logic_cell_macro]
}

# =============================================================================

proc pack {} {

    # Load the plugin that allows to retrieve cell count
    yosys plugin -i get_count

    # Maximum number of LOGIC cells in the device
    set max_logic 891

    # Target number of LOGIC cells. This is less than max to allow the VPR
    # packet to have more freedom.
    set target_logic [expr int($max_logic * 0.75)]

    # LUT3 -> mux2x0 (replace)
    set used_c_frag [get_used_c_frag]
    if {$used_c_frag > $target_logic} {

        # Update
        set required_frags [expr 2 * ($used_c_frag - $target_logic)]
        set used_f_frag [get_used_f_frag]
        set free_f_frag [expr $target_logic - $used_f_frag]

        # Try converting LUT3 to mux2x0
        if {$free_f_frag > 0} {
            puts "Device overfitted ($used_c_frag / $max_logic). Optimizing..."

            set sel_count [min $required_frags $free_f_frag]
            yosys techmap -map $::env(TECHMAP_PATH)/lut3tomux2.v t:LUT3 %R$sel_count
        }
    }

    # LUT2 -> mux2x0 (replace)
    set used_c_frag [get_used_c_frag]
    if {$used_c_frag > $target_logic} {

        # Update
        set required_frags [expr 2 * ($used_c_frag - $target_logic)]
        set used_f_frag [get_used_f_frag]
        set free_f_frag [expr $target_logic - $used_f_frag]

        # Try converting LUT2 to mux2x0
        if {$free_f_frag > 0} {
            puts "Device overfitted ($used_c_frag / $max_logic). Optimizing..."

            set sel_count [min $required_frags $free_f_frag]
            yosys techmap -map $::env(TECHMAP_PATH)/lut2tomux2.v t:LUT2 %R$sel_count
        }
    }

    # Split mux4x0
    set used_c_frag [get_used_c_frag]
    if {$used_c_frag > $target_logic} {

        # Update
        set required_frags [expr 2 * ($used_c_frag - $target_logic)]
        set used_f_frag [get_used_f_frag]
        set free_f_frag [expr $target_logic - $used_f_frag]

        # Try converting mux4x0 to 3x mux2x0
        if {$free_f_frag >= 3} {
            puts "Device overfitted ($used_c_frag / $max_logic). Optimizing..."

            set sel_count [min $required_frags [expr int(floor($free_f_frag / 3.0))]]

            # If there are not enough mux4x0 then map some LUT2 to them (these are
            # actually equivalent)
            set mux4_count [get_count -cells t:mux4x0]
            if {$mux4_count < $sel_count} {
                set map_count [expr $sel_count - $mux4_count]
                yosys techmap -map $::env(TECHMAP_PATH)/lut2tomux4.v t:LUT2 %R$map_count
            }

            yosys techmap -map $::env(TECHMAP_PATH)/mux4tomux2.v t:mux4x0 %R$sel_count
        }
    }
}
pack
