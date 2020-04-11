add_file_target(FILE bidir_iobuf.sim.v SCANNER_TYPE verilog)
add_file_target(FILE bidir.sim.v SCANNER_TYPE verilog)

v2x(NAME bidir_iobuf SRCS bidir_iobuf.sim.v)
v2x(NAME bidir SRCS bidir.sim.v)

add_to_cells_sim(bidir_iobuf.sim.v)

