add_file_target(FILE ram8k_2x1_cell_macro.sim.v SCANNER_TYPE verilog)

v2x(NAME ram8k_2x1_cell_macro SRCS ram8k_2x1_cell_macro.sim.v)

add_to_cells_sim(ram8k_2x1_cell_macro.sim.v)
