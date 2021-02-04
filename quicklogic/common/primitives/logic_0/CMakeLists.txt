add_file_target(FILE logic_0_cell.sim.v SCANNER_TYPE verilog)
add_file_target(FILE logic_0.sim.v SCANNER_TYPE verilog)

v2x(NAME logic_0_cell SRCS logic_0_cell.sim.v)
v2x(NAME logic_0 SRCS logic_0.sim.v)

add_to_cells_sim(logic_0_cell.sim.v COMMON)
