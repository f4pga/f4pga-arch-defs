add_file_target(FILE mult.sim.v SCANNER_TYPE verilog)

add_file_target(FILE mult.pb_type.xml SCANNER_TYPE xml)
add_file_target(FILE mult.model.xml SCANNER_TYPE xml)

add_to_cells_sim(mult.sim.v)
