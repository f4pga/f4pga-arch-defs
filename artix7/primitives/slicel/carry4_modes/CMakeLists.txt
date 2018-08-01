add_subdirectory(carry4)
add_subdirectory(carry4_split)
make_file_target(FILE carry4_modes.sim.v SCANNER_TYPE verilog)
v2x(NAME carry4_modes SRCS carry4_modes.sim.v)
