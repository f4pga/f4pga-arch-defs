add_file_target(FILE clock_cell.sim.v SCANNER_TYPE verilog)

add_file_target(FILE clock_cell.pb_type.xml SCANNER_TYPE xml)
add_file_target(FILE clock_cell.model.xml SCANNER_TYPE xml)
add_file_target(FILE clock.pb_type.xml SCANNER_TYPE xml)
add_file_target(FILE clock.model.xml SCANNER_TYPE xml)

add_to_cells_sim(clock_cell.sim.v)
