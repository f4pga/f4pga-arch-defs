add_file_target(FILE asspl.sim.v SCANNER_TYPE verilog)

add_file_target(FILE asspl.pb_type.xml SCANNER_TYPE xml)
add_file_target(FILE asspl.model.xml SCANNER_TYPE xml)

add_to_cells_sim(asspl.sim.v)
