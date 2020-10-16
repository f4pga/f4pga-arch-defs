add_file_target(FILE clock_cell.sim.v SCANNER_TYPE verilog)
add_file_target(FILE clock.sim.v SCANNER_TYPE verilog)

v2x(NAME clock_cell SRCS clock_cell.sim.v)
v2x(NAME clock SRCS clock.sim.v)

add_to_cells_sim(clock_cell.sim.v)

