add_file_target(FILE asspr.sim.v SCANNER_TYPE verilog)

add_file_target(FILE asspr.pb_type.xml SCANNER_TYPE xml)
add_file_target(FILE asspr.model.xml SCANNER_TYPE xml)

add_to_cells_sim(asspr.sim.v)
