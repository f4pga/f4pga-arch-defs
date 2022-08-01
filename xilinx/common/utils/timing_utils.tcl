proc write_timing_info {filename} {
    # Writes timing data in JSON5 format to filename.
    #
    # Timing data is array of net objects, containing:
    #  - Node layout for each net
    #  - Route taking for each net
    #  - Interconnect delays from opin to each ipin
    #  - Slack and hold timing information for each ipin that has a timing
    #    path.
    set fp [open $filename w]
    puts $fp "\["

    set nets [get_nets]
    foreach net $nets {
        if { $net == "<const0>" || $net == "<const1>" } {
            continue
        }

        if { [get_property ROUTE_STATUS [get_nets $net]] == "INTRASITE" } {
            continue
        }
        if { [get_property ROUTE_STATUS [get_nets $net]] == "NOLOADS" } {
            continue
        }

        puts $fp "{"
            puts $fp "\"net\":\"$net\","

            set route [get_property ROUTE $net]
            puts $fp "\"route\":\"$route\","

            puts $fp "\"nodes\":\["
            set nodes [get_nodes -of_objects $net]
            foreach node $nodes {
                puts $fp "{"
                    puts $fp "\"name\":\"$node\","
                    puts $fp "\"wires\":\["
                    set wires [get_wires -of_objects $node]
                    foreach wire $wires {
                        puts $fp "{"
                            puts $fp "\"name\":\"$wire\","
                        puts $fp "},"
                    }
                    puts $fp "\],"
                puts $fp "},"
            }
            puts $fp "\],"

            set opin [get_pins -leaf -of_objects [get_nets $net] -filter {DIRECTION == OUT}]
            puts $fp "\"opin\": {"
                puts $fp "\"name\":\"$opin\","
                set opin_site_pin [get_site_pins -of_objects $opin]
                puts $fp "\"site_pin\":\"$opin_site_pin\","
                puts $fp "\"node\":\"[get_nodes -of_objects $opin_site_pin]\","
                puts $fp "\"wire\":\"[get_wires -of_objects [get_nodes -of_objects $opin_site_pin]]\","
            puts $fp "},"
            set ipins [get_pins -of_objects [get_nets $net] -filter {DIRECTION == IN} -leaf]
            puts $fp "\"ipins\":\["
            foreach ipin $ipins {
                puts $fp "{"
                    set delay [get_net_delays -interconnect_only -of_objects $net -to $ipin]
                    puts $fp "\"name\":\"$ipin\","
                    puts $fp "\"ic_delays\":{"
                        foreach prop {"FAST_MAX" "FAST_MIN" "SLOW_MAX" "SLOW_MIN"} {
                            puts $fp "\"$prop\":\"[get_property $prop $delay]\","
                        }
                    puts $fp "},"

                    set setup_timing_path [get_timing_paths -to $ipin -setup]
                    set num_setup [llength $setup_timing_path]
                    if { $num_setup > 0 } {
                        if { $num_setup > 1 } {
                            error "Too many setup timing paths, found $num_setup"
                        }
                        puts $fp "\"setup_timing_path\":{"
                            foreach prop [list_property $setup_timing_path] {
                                puts $fp "\"$prop\":\"[get_property $prop $setup_timing_path]\","
                            }
                        puts $fp "},"
                    }

                    set hold_timing_path [get_timing_paths -to $ipin -hold]
                    set num_hold [llength $hold_timing_path]
                    if { $num_hold > 0 } {
                        if { $num_hold > 1 } {
                            error "Too many hold timing paths, found $num_hold"
                        }
                        puts $fp "\"hold_timing_path\":{"
                            foreach prop [list_property $hold_timing_path] {
                                puts $fp "\"$prop\":\"[get_property $prop $hold_timing_path]\","
                            }
                        puts $fp "},"
                    }

                    set ipin_site_pin [get_site_pin -of_objects $ipin]
                    puts $fp "\"site_pin\":\"$ipin_site_pin\","
                    puts $fp "\"node\":\"[get_nodes -of_objects $ipin_site_pin]\","
                    puts $fp "\"wire\":\"[get_wires -of_objects [get_nodes -of_objects $ipin_site_pin]]\","
                puts $fp "},"
            }
            puts $fp "\],"

        puts $fp "},"
    }

    puts $fp "\]"
    close $fp

}

proc output_timing {timing_json} {
    write_timing_info $timing_json
    report_timing_summary
}
