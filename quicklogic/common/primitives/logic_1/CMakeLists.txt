add_file_target(FILE logic_1_cell.sim.v SCANNER_TYPE verilog)
add_file_target(FILE logic_1.sim.v SCANNER_TYPE verilog)

v2x(NAME logic_1_cell SRCS logic_1_cell.sim.v)
v2x(NAME logic_1 SRCS logic_1.sim.v)

add_to_cells_sim(logic_1_cell.sim.v COMMON)
