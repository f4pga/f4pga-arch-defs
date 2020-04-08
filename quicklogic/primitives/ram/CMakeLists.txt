add_file_target(FILE ram.sim.v SCANNER_TYPE verilog)

v2x(NAME ram SRCS ram.sim.v)

add_to_cells_sim(ram.sim.v)
