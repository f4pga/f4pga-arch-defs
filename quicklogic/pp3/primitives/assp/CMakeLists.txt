add_file_target(FILE assp.sim.v SCANNER_TYPE verilog) 
add_file_target(FILE assp_bfm.sim.v SCANNER_TYPE verilog)

v2x(NAME assp SRCS assp.sim.v)

add_to_cells_sim(assp_bfm.sim.v)
