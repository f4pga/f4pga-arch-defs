add_file_target(FILE gmux_ip.sim.v SCANNER_TYPE verilog)
add_file_target(FILE gmux_ic.sim.v SCANNER_TYPE verilog)

add_file_target(FILE gmux_ic.pb_type.xml SCANNER_TYPE xml)
add_file_target(FILE gmux_ic.model.xml SCANNER_TYPE xml)
add_file_target(FILE gmux_ip.pb_type.xml SCANNER_TYPE xml)
add_file_target(FILE gmux_ip.model.xml SCANNER_TYPE xml)
add_file_target(FILE gmux.pb_type.xml SCANNER_TYPE xml)
add_file_target(FILE gmux.model.xml SCANNER_TYPE xml)

add_to_cells_sim(gmux_ip.sim.v)
add_to_cells_sim(gmux_ic.sim.v)
