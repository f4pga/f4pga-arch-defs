add_file_target(FILE bidir_ibuf.sim.v SCANNER_TYPE verilog)
add_file_target(FILE bidir_obuf.sim.v SCANNER_TYPE verilog)
add_file_target(FILE bidir.sim.v SCANNER_TYPE verilog)

v2x(NAME bidir_ibuf SRCS bidir_ibuf.sim.v)
v2x(NAME bidir_obuf SRCS bidir_obuf.sim.v)
v2x(NAME bidir SRCS bidir.sim.v)

add_to_cells_sim(bidir_ibuf.sim.v)
add_to_cells_sim(bidir_obuf.sim.v)
