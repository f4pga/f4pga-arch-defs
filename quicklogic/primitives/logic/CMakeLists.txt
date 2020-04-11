add_file_target(FILE c_frag.sim.v SCANNER_TYPE verilog)
add_file_target(FILE q_frag.sim.v SCANNER_TYPE verilog)
add_file_target(FILE f_frag.sim.v SCANNER_TYPE verilog)
add_file_target(FILE logic.sim.v SCANNER_TYPE verilog)

v2x(NAME c_frag SRCS c_frag.sim.v)
v2x(NAME q_frag SRCS q_frag.sim.v)
v2x(NAME f_frag SRCS f_frag.sim.v)
v2x(NAME logic  SRCS logic.sim.v)

add_to_cells_sim(c_frag.sim.v)
add_to_cells_sim(q_frag.sim.v)
add_to_cells_sim(f_frag.sim.v)
