add_file_target(FILE sdiomux_site.sim.v SCANNER_TYPE verilog)
add_file_target(FILE sdiomux.sim.v SCANNER_TYPE verilog)

v2x(NAME sdiomux_site SRCS sdiomux_site.sim.v)
v2x(NAME sdiomux SRCS sdiomux.sim.v)

add_to_cells_sim(sdiomux_site.sim.v)

