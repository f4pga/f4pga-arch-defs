add_file_target(FILE assp_ram2048x32b.sim.v SCANNER_TYPE verilog)

add_file_target(FILE assp_ram2048x32b.pb_type.xml SCANNER_TYPE xml)
add_file_target(FILE assp_ram2048x32b.model.xml SCANNER_TYPE xml)

add_to_cells_sim(assp_ram2048x32b.sim.v)
