add_file_target(FILE gmux_ip.sim.v SCANNER_TYPE verilog)
add_file_target(FILE gmux_ic.sim.v SCANNER_TYPE verilog)
add_file_target(FILE gmux.sim.v SCANNER_TYPE verilog)

v2x(NAME gmux_ip SRCS gmux_ip.sim.v)
v2x(NAME gmux_ic SRCS gmux_ic.sim.v)
v2x(NAME gmux SRCS gmux.sim.v)

add_to_cells_sim(gmux_ip.sim.v)
add_to_cells_sim(gmux_ic.sim.v)

add_file_target(FILE gmux_proxy.v SCANNER_TYPE verilog)
add_to_cells_sim(gmux_proxy.v)
