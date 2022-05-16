add_file_target(FILE assp.sim.v SCANNER_TYPE verilog)

add_file_target(FILE assp.pb_type.xml SCANNER_TYPE xml)
add_file_target(FILE assp.model.xml SCANNER_TYPE xml)

add_to_cells_sim(assp.sim.v)
