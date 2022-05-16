add_file_target(FILE bidir_cell.sim.v SCANNER_TYPE verilog)

add_file_target(FILE bidir_cell.pb_type.xml SCANNER_TYPE xml)
add_file_target(FILE bidir_cell.model.xml SCANNER_TYPE xml)
add_file_target(FILE bidir.pb_type.xml SCANNER_TYPE xml)
add_file_target(FILE bidir.model.xml SCANNER_TYPE xml)

add_to_cells_sim(bidir_cell.sim.v)

