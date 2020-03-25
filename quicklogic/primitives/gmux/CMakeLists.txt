add_file_target(FILE gmux.sim.v SCANNER_TYPE verilog)

v2x(NAME gmux SRCS gmux.sim.v)

add_to_cells_sim(gmux.sim.v)
