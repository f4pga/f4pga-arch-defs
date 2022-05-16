add_file_target(FILE sdiomux_cell.sim.v SCANNER_TYPE verilog)

add_file_target(FILE sdiomux_cell.pb_type.xml SCANNER_TYPE xml)
add_file_target(FILE sdiomux_cell.model.xml SCANNER_TYPE xml)
add_file_target(FILE sdiomux.pb_type.xml SCANNER_TYPE xml)
add_file_target(FILE sdiomux.model.xml SCANNER_TYPE xml)

add_to_cells_sim(sdiomux_cell.sim.v)

