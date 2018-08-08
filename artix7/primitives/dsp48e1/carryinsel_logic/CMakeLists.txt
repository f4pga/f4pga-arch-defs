add_subdirectory(carryin_mux)
add_file_target(FILE carryinsel_logic.sim.v SCANNER_TYPE verilog)
v2x(NAME carryinsel_logic SRCS carryinsel_logic.sim.v)
