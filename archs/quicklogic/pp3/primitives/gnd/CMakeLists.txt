add_file_target(FILE gnd.sim.v SCANNER_TYPE verilog)

add_file_target(FILE gnd.pb_type.xml SCANNER_TYPE xml)
add_file_target(FILE gnd.model.xml SCANNER_TYPE xml)

add_to_cells_sim(gnd.sim.v)
