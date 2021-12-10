add_file_target(FILE assp_mult.sim.v SCANNER_TYPE verilog)

add_file_target(FILE assp_mult.pb_type.xml SCANNER_TYPE xml)
add_file_target(FILE assp_mult.model.xml SCANNER_TYPE xml)

add_to_cells_sim(assp_mult.sim.v)
