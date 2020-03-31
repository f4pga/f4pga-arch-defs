add_file_target(FILE iobuf.sim.v SCANNER_TYPE verilog)
add_file_target(FILE iob.sim.v SCANNER_TYPE verilog)

v2x(NAME iobuf SRCS iobuf.sim.v)
v2x(NAME iob SRCS iob.sim.v)

add_to_cells_sim(iobuf.sim.v)

