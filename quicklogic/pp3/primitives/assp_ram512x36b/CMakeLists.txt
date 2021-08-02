add_file_target(FILE assp_ram512x36b.sim.v SCANNER_TYPE verilog)

add_file_target(FILE assp_ram512x36b.pb_type.xml SCANNER_TYPE xml)
add_file_target(FILE assp_ram512x36b.model.xml SCANNER_TYPE xml)

add_to_cells_sim(assp_ram512x36b.sim.v)
