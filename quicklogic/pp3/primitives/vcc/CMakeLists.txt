add_file_target(FILE vcc.sim.v SCANNER_TYPE verilog)

add_file_target(FILE vcc.pb_type.xml SCANNER_TYPE xml)
add_file_target(FILE vcc.model.xml SCANNER_TYPE xml)

add_to_cells_sim(vcc.sim.v)
