add_file_target(FILE gnd.sim.v SCANNER_TYPE verilog)

v2x(NAME gnd SRCS gnd.sim.v)

add_to_cells_sim(gnd.sim.v)
