add_file_target(FILE ff.sim.v SCANNER_TYPE verilog)
v2x(NAME ff SRCS ff.sim.v)
add_to_cells_sim(ff.sim.v)
