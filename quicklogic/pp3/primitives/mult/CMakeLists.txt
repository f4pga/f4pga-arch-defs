add_file_target(FILE mult.sim.v SCANNER_TYPE verilog)

v2x(NAME mult SRCS mult.sim.v)

add_to_cells_sim(mult.sim.v)
