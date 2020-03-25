add_file_target(FILE clock_iobuf.sim.v SCANNER_TYPE verilog)
add_file_target(FILE clock.sim.v SCANNER_TYPE verilog)

v2x(NAME clock_iobuf SRCS clock_iobuf.sim.v)
v2x(NAME clock SRCS clock.sim.v)

add_to_cells_sim(clock_iobuf.sim.v)

