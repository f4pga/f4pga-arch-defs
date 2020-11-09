add_file_target(FILE bidir_cell.sim.v SCANNER_TYPE verilog)
add_file_target(FILE bidir.sim.v SCANNER_TYPE verilog)

v2x(NAME bidir_cell SRCS bidir_cell.sim.v)
v2x(NAME bidir SRCS bidir.sim.v)

add_to_cells_sim(bidir_cell.sim.v)

